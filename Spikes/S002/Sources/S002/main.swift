import AppKit

// Usage: S002 [--seconds N] [--behavior base|spacesOnly|stationary]
//             [--level mainMenu|statusBar|popUpMenu|screenSaver] [--info]
// Quits by itself after --seconds (default 300). Ctrl+C in the terminal also stops it.

struct Options {
    var seconds = 300
    var behavior = BehaviorChoice.base
    var level = LevelChoice.statusBar
    var infoOnly = false

    init(arguments: [String]) {
        var it = arguments.dropFirst().makeIterator()
        while let arg = it.next() {
            switch arg {
            case "--seconds": seconds = it.next().flatMap(Int.init) ?? seconds
            case "--behavior": behavior = it.next().flatMap(BehaviorChoice.init(rawValue:)) ?? behavior
            case "--level": level = it.next().flatMap(LevelChoice.init(rawValue:)) ?? level
            case "--info": infoOnly = true
            default: print("unknown argument ignored: \(arg)")
            }
        }
    }
}

setvbuf(stdout, nil, _IOLBF, 0) // keep log lines when output goes to a file
let options = Options(arguments: CommandLine.arguments)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

Monitor.printScreens()
guard !options.infoOnly else { exit(0) }
guard let startFrame = Monitor.expectedFrame() else {
    print("no screen reports a notch; stopping")
    exit(1)
}

print("behavior \(options.behavior.rawValue) level \(options.level.rawValue) (raw \(options.level.level.rawValue))")
let monitor = Monitor()
monitor.show(frame: startFrame, level: options.level.level, behavior: options.behavior.behavior)

Task { @MainActor in
    try? await Task.sleep(for: .seconds(options.seconds))
    print("auto-quit after \(options.seconds) s")
    monitor.stop()
    app.terminate(nil)
}

print("running; Ctrl+C or wait \(options.seconds) s to stop")
app.run()
