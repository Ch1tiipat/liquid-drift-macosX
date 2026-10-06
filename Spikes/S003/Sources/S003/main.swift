import AppKit

// Usage: S003 [--seconds N] [--level statusBar|popUpMenu] [--behavior base|stationary]
//             [--zone ALPHA] [--watch] [--info]
//   --zone ALPHA  add a larger hot-zone window around the notch with this background alpha (0 to 1)
//   --watch       Q2: watch the drag pasteboard and install a global leftMouseDragged monitor
//   --zone-on-drag  with --zone: keep the zone at alpha 0 and switch it to 0.01 only while a drag is seen (Q2a)
//   --collapse-delay MS  wait this long with no hovered view before the pill collapses (default 250, 0 = immediate)
// Send SIGUSR1 (kill -USR1 <pid>) to resolve all stored bookmarks.
// Quits by itself after --seconds (default 300). Ctrl+C in the terminal also stops it.

struct Options {
    var seconds = 300
    var level = LevelChoice.statusBar
    var behavior = BehaviorChoice.stationary
    var zoneAlpha: CGFloat?
    var watch = false
    var zoneOnDrag = false
    var collapseDelayMS = 250
    var infoOnly = false

    init(arguments: [String]) {
        var it = arguments.dropFirst().makeIterator()
        while let arg = it.next() {
            switch arg {
            case "--seconds": seconds = it.next().flatMap(Int.init) ?? seconds
            case "--level": level = it.next().flatMap(LevelChoice.init(rawValue:)) ?? level
            case "--behavior": behavior = it.next().flatMap(BehaviorChoice.init(rawValue:)) ?? behavior
            case "--zone": zoneAlpha = it.next().flatMap(Double.init).map { CGFloat($0) }
            case "--watch": watch = true
            case "--zone-on-drag": zoneOnDrag = true
            case "--collapse-delay": collapseDelayMS = it.next().flatMap(Int.init) ?? collapseDelayMS
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

guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }),
      let notch = NotchGeometry(screen: screen).notchFromEdges else {
    print("no screen reports a notch; stopping")
    exit(1)
}
print(NotchGeometry(screen: screen).report(index: 0))
guard !options.infoOnly else { exit(0) }

let pillFrame = PanelVariant.b.frame(forNotch: notch)
// Expanded pill: 60 pt wider on each side and 60 pt taller below.
let expandedFrame = NSRect(x: pillFrame.minX - 60, y: pillFrame.minY - 60, width: pillFrame.width + 120, height: pillFrame.height + 60)
// Hot zone: notch plus 80 pt on each side, 120 pt tall from the top edge.
let zoneFrame = NSRect(x: notch.minX - 80, y: screen.frame.maxY - 120, width: notch.width + 160, height: 120)

let report = DropReport()
/// Views the drag is over. The pill collapses only after this stays empty for a short delay,
/// because expanding the pill under the cursor makes the zone report an exit (S-003 finding).
var hovered: Set<String> = []
var collapseTask: Task<Void, Never>?
let collapseDelay: Duration = .milliseconds(options.collapseDelayMS)

@MainActor
func setExpanded(_ panel: NSPanel, _ expanded: Bool) {
    panel.setFrame(expanded ? expandedFrame : pillFrame, display: true)
    Log.line("pill \(expanded ? "expanded" : "collapsed") frame \(panel.frame)")
}

@MainActor
func wire(_ view: DropView, name: String, pill: @escaping @MainActor () -> NSPanel?) {
    view.onEnter = { info in
        let wasEmpty = hovered.isEmpty
        hovered.insert(name)
        collapseTask?.cancel()
        Log.line("\(name) draggingEntered " + report.describe(info) + " " + Log.focus())
        if wasEmpty, let pill = pill(), pill.frame != expandedFrame { setExpanded(pill, true) }
    }
    view.onExit = {
        hovered.remove(name)
        Log.line("\(name) draggingExited")
        guard hovered.isEmpty else { return }
        collapseTask?.cancel()
        collapseTask = Task { @MainActor in
            try? await Task.sleep(for: collapseDelay)
            guard !Task.isCancelled, hovered.isEmpty, let pill = pill() else { return }
            setExpanded(pill, false)
        }
    }
    view.onMouseDown = {
        Log.line("\(name) mouseDown (click caught by this window) " + Log.focus())
    }
    view.onDrop = { info in
        Log.line("\(name) performDragOperation " + report.describe(info) + " " + Log.focus())
        report.storeBookmarks(info)
        hovered.removeAll()
        collapseTask?.cancel()
        if let pill = pill() { setExpanded(pill, false) }
        return true
    }
}

var pillPanel: NotchPanel?
var zonePanel: NotchPanel?

if let alpha = options.zoneAlpha {
    let zoneView = DropView(fill: NSColor(white: 1, alpha: alpha), border: nil, label: nil)
    wire(zoneView, name: "zone") { pillPanel }
    let zone = NotchPanel(frame: zoneFrame, level: options.level.level, behavior: options.behavior.behavior, content: zoneView)
    zone.orderFrontRegardless()
    zonePanel = zone
    Log.line("hot zone shown alpha=\(alpha) frame \(zone.frame)")
}

let pillView = DropView(fill: NSColor(white: 0.05, alpha: 1), border: .systemGreen, label: "S-003")
wire(pillView, name: "pill") { pillPanel }
let pill = NotchPanel(frame: pillFrame, level: options.level.level, behavior: options.behavior.behavior, content: pillView)
pill.orderFrontRegardless()
pillPanel = pill
Log.line("pill shown level \(options.level.rawValue) behavior \(options.behavior.rawValue) frame \(pill.frame) " + Log.focus())
Log.line("pid \(ProcessInfo.processInfo.processIdentifier)")

let watch = DragWatch()
if options.watch {
    watch.startPasteboardPoll()
    watch.startGlobalMonitor()
}
if options.zoneOnDrag, let zone = zonePanel {
    // Zone stays fully transparent (clicks pass through) and turns near-transparent only during a drag.
    zone.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    watch.onDragStart = {
        zone.contentView?.layer?.backgroundColor = NSColor(white: 1, alpha: 0.01).cgColor
        Log.line("zone armed for drag (alpha 0.01)")
    }
    watch.onDragEnd = {
        zone.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        Log.line("zone disarmed (alpha 0)")
    }
    if !options.watch { watch.startPasteboardPoll() }
}

signal(SIGUSR1, SIG_IGN)
let resolveSignal = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
resolveSignal.setEventHandler {
    MainActor.assumeIsolated { report.resolveAll() }
}
resolveSignal.resume()

Task { @MainActor in
    try? await Task.sleep(for: .seconds(options.seconds))
    Log.line("auto-quit after \(options.seconds) s")
    watch.stop()
    resolveSignal.cancel()
    app.terminate(nil)
}

print("running; Ctrl+C or wait \(options.seconds) s to stop")
app.run()
