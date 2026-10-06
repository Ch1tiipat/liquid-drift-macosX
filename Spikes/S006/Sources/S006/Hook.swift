import Foundation

/// Hook helper (option A). Appends one line "<event name> <epoch ms>" to <scratch>/events.log.
/// Claude Code mode reads and discards the JSON payload on stdin.
/// Codex mode keeps exactly one field, `transcript_path`, and only when the payload's `cwd` is the
/// scratch folder; it is written to <scratch>/codex-transcript-path so the watcher knows the file
/// before the first prompt. Nothing else from the payload is stored or printed.
enum Hook {
    static let transcriptListName = "codex-transcript-path"
    private static let maxPayloadBytes = 1024 * 1024

    static func run(event: String, pathGuard: PathGuard, captureTranscript: Bool) -> Int32 {
        let payload = FileHandle.standardInput.readDataToEndOfFile()
        if captureTranscript, payload.count <= maxPayloadBytes {
            recordTranscriptPath(from: payload, pathGuard: pathGuard)
        }
        let allowed = event.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) } && event.count <= 40
        return append("\(allowed ? event : "invalid") \(Stamp.nowMS())\n", to: pathGuard.scratch + "/events.log")
    }

    private static func recordTranscriptPath(from payload: Data, pathGuard: PathGuard) {
        guard let object = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
              let cwd = object["cwd"] as? String, PathGuard.resolve(cwd) == pathGuard.scratch,
              let transcript = object["transcript_path"] as? String,
              pathGuard.allowsCodexTranscript(transcript) else { return }
        let listFile = pathGuard.scratch + "/" + transcriptListName
        let known = (try? String(contentsOfFile: listFile, encoding: .utf8)) ?? ""
        guard !known.split(separator: "\n").contains(Substring(transcript)) else { return }
        _ = append(transcript + "\n", to: listFile)
    }

    private static func append(_ text: String, to file: String) -> Int32 {
        guard let data = text.data(using: .utf8) else { return 1 }
        let fd = open(file, O_WRONLY | O_APPEND | O_CREAT, 0o600)
        guard fd >= 0 else { return 1 }
        defer { close(fd) }
        let written = data.withUnsafeBytes { write(fd, $0.baseAddress, $0.count) }
        return written == data.count ? 0 : 1
    }
}
