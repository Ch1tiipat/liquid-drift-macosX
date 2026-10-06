import AppKit

// Usage: S001 [--seconds N] [--variant A|B] [--level mainMenu|statusBar|popUpMenu|screenSaver|custom]
//             [--hotkey none|carbon|monitor] [--info]
// Quits by itself after --seconds (default 180). Ctrl+C in Terminal also stops it.

struct Options {
    var seconds = 180
    var variant = PanelVariant.a
    var level = LevelChoice.statusBar
    var hotkey = "none"
    var infoOnly = false

    init(arguments: [String]) {
        var it = arguments.dropFirst().makeIterator()
        while let arg = it.next() {
            switch arg {
            case "--seconds": seconds = it.next().flatMap(Int.init) ?? seconds
            case "--variant": variant = it.next().flatMap(PanelVariant.init(rawValue:)) ?? variant
            case "--level": level = it.next().flatMap(LevelChoice.init(rawValue:)) ?? level
            case "--hotkey": hotkey = it.next() ?? hotkey
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

@MainActor
func printScreens() {
    for (index, screen) in NSScreen.screens.enumerated() {
        print(NotchGeometry(screen: screen).report(index: index))
    }
}

@MainActor
func mainNotch() -> NSRect? {
    guard let screen = NSScreen.main else { return nil }
    return NotchGeometry(screen: screen).notchFromEdges
}

print("levels rawValue: " + LevelChoice.allCases.map { "\($0.rawValue)=\($0.level.rawValue)" }.joined(separator: " "))
printScreens()

guard !options.infoOnly else { exit(0) }
guard let notch = mainNotch() else {
    print("main screen reports no notch; stopping")
    exit(1)
}

let panel = NotchPanel(frame: options.variant.frame(forNotch: notch), level: options.level.level)
print("variant \(options.variant.rawValue) level \(options.level.rawValue) panel frame \(panel.frame)")

let frontBefore = NSWorkspace.shared.frontmostApplication?.processIdentifier
panel.orderFrontRegardless()

let screenObserver = NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
) { _ in
    MainActor.assumeIsolated {
        print("screen parameters changed")
        printScreens()
        if let notch = mainNotch() {
            panel.setFrame(options.variant.frame(forNotch: notch), display: true)
            print("panel moved to \(panel.frame)")
        } else {
            print("no notch after change")
        }
    }
}

HotkeyRouter.onToggle = {
    if panel.isVisible { panel.orderOut(nil) } else { panel.orderFrontRegardless() }
    print("hotkey: panel visible = \(panel.isVisible)")
}

let carbon = CarbonHotkey()
let globalMonitor = GlobalMonitorHotkey()
switch options.hotkey {
case "carbon":
    print("carbon RegisterEventHotKey status = \(carbon.register())")
case "monitor":
    print("AXIsProcessTrusted (no prompt) = \(GlobalMonitorHotkey.isTrusted)")
    print("global monitor installed = \(globalMonitor.register())")
default:
    break
}

Task { @MainActor in
    try? await Task.sleep(for: .milliseconds(500))
    let frontAfter = NSWorkspace.shared.frontmostApplication?.processIdentifier
    print("frontmost application unchanged: \(frontBefore == frontAfter)")
    try? await Task.sleep(for: .seconds(options.seconds))
    print("auto-quit after \(options.seconds) s")
    carbon.unregister()
    globalMonitor.unregister()
    NotificationCenter.default.removeObserver(screenObserver)
    app.terminate(nil)
}

print("running; Ctrl+C or wait \(options.seconds) s to stop")
app.run()
