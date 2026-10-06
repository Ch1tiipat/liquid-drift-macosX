import AppKit

/// Owns the panel, logs its state on every event, and keeps it on the notch.
@MainActor
final class Monitor {
    private let ownPID = ProcessInfo.processInfo.processIdentifier
    private var lastFrontPID: pid_t?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private(set) var panel: NotchPanel?

    /// The built-in screen is the one that reports a notch.
    static func notchScreen() -> NSScreen? {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 }
    }

    /// Expected panel frame from the current screen values (S-001 variant B).
    static func expectedFrame() -> NSRect? {
        guard let screen = notchScreen(), let notch = NotchGeometry(screen: screen).notchFromEdges else { return nil }
        return PanelVariant.b.frame(forNotch: notch)
    }

    /// MISMATCH only when a value differs by more than 1.0 pt.
    nonisolated static func isMismatch(_ frame: NSRect, _ expected: NSRect) -> Bool {
        let tolerance: CGFloat = 1.0
        return abs(frame.minX - expected.minX) > tolerance
            || abs(frame.minY - expected.minY) > tolerance
            || abs(frame.width - expected.width) > tolerance
            || abs(frame.height - expected.height) > tolerance
    }

    nonisolated static func describe(_ rect: NSRect) -> String {
        "(\(rect.minX), \(rect.minY), \(rect.width), \(rect.height))"
    }

    static func printScreens() {
        for (index, screen) in NSScreen.screens.enumerated() {
            print(NotchGeometry(screen: screen).report(index: index))
        }
    }

    func show(frame: NSRect, level: NSWindow.Level, behavior: NSWindow.CollectionBehavior) {
        lastFrontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let panel = NotchPanel(frame: frame, level: level, behavior: behavior) { [weak self] in
            self?.log("panel click")
        }
        self.panel = panel
        panel.orderFrontRegardless()
        log("shown")
        startObserving(panel)
    }

    func log(_ event: String) {
        guard let panel else { return }
        let frame = panel.frame
        let front = NSWorkspace.shared.frontmostApplication?.processIdentifier
        var line = "[\(event)] frame \(Self.describe(frame))"
        if let expected = Self.expectedFrame() {
            line += " expected \(Self.describe(expected))"
            if Self.isMismatch(frame, expected) { line += " FRAME MISMATCH" }
        } else {
            line += " expected none (no notch screen)"
        }
        line += " isVisible=\(panel.isVisible)"
        line += " occlusionVisible=\(panel.occlusionState.contains(.visible))"
        line += " frontmost application unchanged: \(front == lastFrontPID)"
        line += " spike is frontmost: \(front == ownPID)"
        print(line)
        lastFrontPID = front
    }

    private func reposition() {
        guard let panel, let expected = Self.expectedFrame() else { return }
        panel.setFrame(expected, display: true)
    }

    private func startObserving(_ panel: NotchPanel) {
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.activeSpaceDidChangeNotification, label: "activeSpaceDidChange")
        observe(workspace, NSWorkspace.willSleepNotification, label: "willSleep")
        observe(workspace, NSWorkspace.didWakeNotification, label: "didWake")
        observe(workspace, NSWorkspace.screensDidWakeNotification, label: "screensDidWake")
        observe(.default, NSApplication.didChangeScreenParametersNotification, label: "didChangeScreenParameters") { monitor in
            Monitor.printScreens()
            monitor.reposition()
            monitor.log("didChangeScreenParameters after reposition")
        }
        observe(.default, NSWindow.didMoveNotification, object: panel, label: "panel didMove")
        observe(.default, NSWindow.didChangeScreenNotification, object: panel, label: "panel didChangeScreen")
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        object: AnyObject? = nil,
        label: String,
        then: (@MainActor (Monitor) -> Void)? = nil
    ) {
        let token = center.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
            // queue: .main delivers on the main thread.
            MainActor.assumeIsolated {
                guard let self else { return }
                self.log(label)
                then?(self)
            }
        }
        observers.append((center, token))
    }

    func stop() {
        for (center, token) in observers { center.removeObserver(token) }
        observers.removeAll()
        panel?.orderOut(nil)
    }
}
