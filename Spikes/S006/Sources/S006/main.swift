import Foundation

// Usage:
//   S006 hook <EventName> <scratch> [--codex]
//                                        hook helper: appends "<event> <epoch ms>" to <scratch>/events.log;
//                                        with --codex it also records the transcript path (see Hook.swift)
//   S006 check <scratch>                 says whether the computed session folder exists (prints no path)
//   S006 watch <scratch> [--tool claude|codex] [--seconds N] [--shapes]
//                                        watch option A (events file) and option B (session folder)
//   S006 classify <scratch> <file> [--tool claude|codex]
//                                        run the classifier over a whole file (format-change test)
// <scratch> must be a direct child of $TMPDIR whose name starts with "s006-".
// watch quits by itself after --seconds (default 300). Ctrl+C also stops it.

setvbuf(stdout, nil, _IOLBF, 0)
let arguments = Array(CommandLine.arguments.dropFirst())

func scratchGuard(_ index: Int) -> PathGuard {
    guard arguments.count > index, let pathGuard = PathGuard(scratchArgument: arguments[index]) else {
        print("refused: scratch folder must be a direct child of $TMPDIR named s006-*")
        exit(2)
    }
    return pathGuard
}

func toolOption() -> Tool {
    guard let i = arguments.firstIndex(of: "--tool"), i + 1 < arguments.count else { return .claude }
    return Tool(rawValue: arguments[i + 1]) ?? .claude
}

switch arguments.first {
case "hook":
    guard arguments.count >= 3 else { exit(2) }
    let pathGuard = scratchGuard(2)
    exit(Hook.run(event: arguments[1], pathGuard: pathGuard, captureTranscript: arguments.contains("--codex")))

case "check":
    let pathGuard = scratchGuard(1)
    print("computed session folders found: \(pathGuard.sessionDirs.count)")

case "classify":
    let pathGuard = scratchGuard(1)
    guard arguments.count >= 3, pathGuard.allows(arguments[2]),
          let data = FileManager.default.contents(atPath: arguments[2]) else {
        print("refused or unreadable file")
        exit(2)
    }
    var classifier: any SessionClassifier = toolOption() == .codex ? CodexClassifier() : ClaudeClassifier()
    var lines = 0
    for line in data.split(separator: 0x0A) {
        lines += 1
        guard let shape = LineShape(line: Data(line)) else { print("line \(lines): not JSON -> unknown"); continue }
        if let changed = classifier.feed(shape) { print("line \(lines): state -> \(changed.rawValue)") }
    }
    print("lines \(lines), final state \(classifier.state.rawValue)")

case "watch":
    let pathGuard = scratchGuard(1)
    var seconds = 300
    if let i = arguments.firstIndex(of: "--seconds"), i + 1 < arguments.count, let n = Int(arguments[i + 1]) { seconds = n }
    let shapes = arguments.contains("--shapes")
    print("pid \(ProcessInfo.processInfo.processIdentifier), stops after \(seconds) s or Ctrl+C")
    signal(SIGINT, SIG_IGN)
    let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    MainActor.assumeIsolated {
        let watcher = Watcher(pathGuard: pathGuard, tool: toolOption(), printShapes: shapes)
        watcher.start()
        sigint.setEventHandler { MainActor.assumeIsolated { watcher.stop(); print("stopped by Ctrl+C"); exit(0) } }
        sigint.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
            MainActor.assumeIsolated { watcher.stop(); print("stopped after \(seconds) s"); exit(0) }
        }
    }
    dispatchMain()

default:
    print("usage: S006 hook|check|watch|classify <scratch> ...")
    exit(2)
}
