import Foundation

enum Tool: String { case claude, codex }

/// Watches the scratch events file (option A) and the session data (option B) with DispatchSource
/// vnode sources. Claude Code: the session folder computed from the scratch path. Codex: the exact
/// transcript files the hook helper recorded. Prints only timestamps, file numbers, shapes and states.
@MainActor
final class Watcher {
    private var pathGuard: PathGuard
    private let eventsFile: String
    private let printShapes: Bool
    private let tool: Tool
    private var codexListOffset: UInt64 = 0
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private var offsets: [String: UInt64] = [:]
    private var partial: [String: Data] = [:]
    private var fileNumbers: [String: Int] = [:]
    private var classifiers: [String: any SessionClassifier] = [:]
    private var lastHookMS: Int64?
    static let maxReadBytes = 1024 * 1024

    init(pathGuard: PathGuard, tool: Tool, printShapes: Bool) {
        self.pathGuard = pathGuard
        self.tool = tool
        self.eventsFile = pathGuard.scratch + "/events.log"
        self.printShapes = printShapes
    }

    func start() {
        if !FileManager.default.fileExists(atPath: eventsFile) {
            FileManager.default.createFile(atPath: eventsFile, contents: nil, attributes: [.posixPermissions: 0o600])
        }
        watchFile(eventsFile, fromEnd: true)
        if tool == .codex {
            print("\(Stamp.nowMS()) waiting for the hook helper to record a Codex transcript path")
            pollCodexTranscriptList()
            return
        }
        guard let dir = pathGuard.sessionDirs.first else {
            print("\(Stamp.nowMS()) session folder not there yet; checking the computed path every 100 ms")
            waitForSessionFolder()
            return
        }
        watchDirectory(dir, initial: true)
        print("watching events file and \(pathGuard.sessionDirs.count) session folder(s)")
    }

    /// Checks only the exact computed path (never lists a parent folder) until it exists.
    private func waitForSessionFolder() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                if let fresh = PathGuard(scratchArgument: self.pathGuard.scratch), let dir = fresh.sessionDirs.first {
                    self.pathGuard = fresh
                    print("\(Stamp.nowMS()) B session folder appeared")
                    self.watchDirectory(dir, initial: false)
                } else {
                    self.waitForSessionFolder()
                }
            }
        }
    }

    /// Reads new lines of <scratch>/codex-transcript-path every 100 ms. Each path is checked again by the guard.
    private func pollCodexTranscriptList() {
        let listFile = pathGuard.scratch + "/" + Hook.transcriptListName
        if pathGuard.allows(listFile), let handle = FileHandle(forReadingAtPath: listFile) {
            defer { try? handle.close() }
            if (try? handle.seek(toOffset: codexListOffset)) != nil, let data = try? handle.readToEnd(), !data.isEmpty,
               let lastNewline = data.lastIndex(of: 0x0A) {
                let complete = data[data.startIndex...lastNewline]
                codexListOffset += UInt64(complete.count)
                for path in String(decoding: complete, as: UTF8.self).split(separator: "\n").map(String.init) {
                    guard pathGuard.allowsCodexTranscript(path) else { print("guard refused a transcript path"); continue }
                    if sources[path] == nil { waitForCodexFile(path) }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            MainActor.assumeIsolated { self?.pollCodexTranscriptList() }
        }
    }

    /// The hook may name the file before Codex creates it: check that one exact path until it exists.
    private func waitForCodexFile(_ path: String) {
        if FileManager.default.fileExists(atPath: path) {
            watchFile(path, fromEnd: false)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            MainActor.assumeIsolated { self?.waitForCodexFile(path) }
        }
    }

    private func watchDirectory(_ dir: String, initial: Bool) {
        guard pathGuard.allows(dir) else { print("guard refused a folder"); return }
        scanDirectory(dir, initial: initial)
        addSource(path: dir, mask: [.write]) { [weak self] in self?.scanDirectory(dir, initial: false) }
    }

    private func scanDirectory(_ dir: String, initial: Bool) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []
        for name in names where name.hasSuffix(".jsonl") {
            let path = dir + "/" + name
            if sources[path] == nil { watchFile(path, fromEnd: initial) }
        }
    }

    private func watchFile(_ path: String, fromEnd: Bool) {
        let allowed = path == eventsFile || (tool == .codex ? pathGuard.allowsCodexTranscript(path) : pathGuard.allows(path))
        guard sources[path] == nil else { return } // already watched
        guard allowed else { print("guard refused a file"); return }
        let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.uint64Value ?? 0
        offsets[path] = fromEnd ? size : 0
        if path != eventsFile {
            fileNumbers[path] = fileNumbers.count + 1
            classifiers[path] = tool == .codex ? CodexClassifier() as any SessionClassifier : ClaudeClassifier()
            print("\(Stamp.nowMS()) B file#\(fileNumbers[path] ?? 0) seen (start offset \(fromEnd ? "end" : "0"))")
        }
        addSource(path: path, mask: [.write, .extend]) { [weak self] in self?.readNew(path) }
        readNew(path)
    }

    private func addSource(path: String, mask: DispatchSource.FileSystemEvent, handler: @escaping @MainActor () -> Void) {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { print("could not open a watched path (errno \(errno))"); return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: mask, queue: .main)
        source.setEventHandler { MainActor.assumeIsolated { handler() } }
        source.setCancelHandler { close(fd) }
        sources[path] = source
        source.resume()
    }

    private func readNew(_ path: String) {
        let now = Stamp.nowMS()
        guard let handle = FileHandle(forReadingAtPath: path) else { return }
        defer { try? handle.close() }
        let offset = offsets[path] ?? 0
        do { try handle.seek(toOffset: offset) } catch { return }
        // Read in 1 MB chunks until the end, so a large append is not left half read.
        while let data = try? handle.read(upToCount: Self.maxReadBytes), !data.isEmpty {
            offsets[path] = (offsets[path] ?? 0) + UInt64(data.count)
            var buffer = (partial[path] ?? Data()) + data
            while let newline = buffer.firstIndex(of: 0x0A) {
                let line = buffer[buffer.startIndex..<newline]
                buffer = Data(buffer[buffer.index(after: newline)...])
                handleLine(Data(line), path: path, now: now)
            }
            partial[path] = buffer.count > LineShape.maxLineBytes ? Data() : buffer
        }
    }

    private func handleLine(_ line: Data, path: String, now: Int64) {
        if path == eventsFile {
            let parts = String(decoding: line, as: UTF8.self).split(separator: " ")
            guard parts.count == 2, let hookMS = Int64(parts[1]) else { return }
            lastHookMS = hookMS
            print("\(now) A hook \(parts[0]) seen +\(now - hookMS) ms after hook ran")
            return
        }
        let number = fileNumbers[path] ?? 0
        guard let shape = LineShape(line: line) else {
            print("\(now) B file#\(number) line not readable as JSON object -> unknown")
            return
        }
        let sinceHook = lastHookMS.map { " (+\(now - $0) ms after last hook)" } ?? ""
        if printShapes { print("\(now) B file#\(number) \(shape.summary)") }
        if let changed = classifiers[path]?.feed(shape) {
            print("\(now) B file#\(number) state -> \(changed.rawValue)\(sinceHook)")
        }
    }

    func stop() {
        sources.values.forEach { $0.cancel() }
        sources.removeAll()
    }
}
