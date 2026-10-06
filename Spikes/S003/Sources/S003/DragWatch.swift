import AppKit
import ApplicationServices
import CoreGraphics

/// Q2: ways to notice a drag before it reaches the panel.
@MainActor
final class DragWatch {
    private var pollTask: Task<Void, Never>?
    private var monitor: Any?
    private var dragEventsThisSecond = 0
    private var dragEventsTotal = 0
    private var reportTask: Task<Void, Never>?

    /// Called when a drag starts (drag pasteboard changed while the button is down) and when the button is released.
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?

    /// Q2a: watch the drag pasteboard change count while the left mouse button is down.
    func startPasteboardPoll() {
        let drag = NSPasteboard(name: .drag)
        var lastCount = drag.changeCount
        var dragging = false
        Log.line("drag pasteboard poll started, changeCount=\(lastCount)")
        pollTask = Task { @MainActor in
            while !Task.isCancelled {
                let mouseDown = NSEvent.pressedMouseButtons & 1 == 1
                if mouseDown {
                    let count = drag.changeCount
                    if count != lastCount {
                        Log.line("drag pasteboard changeCount \(lastCount) -> \(count) while mouse down")
                        lastCount = count
                        if !dragging {
                            dragging = true
                            onDragStart?()
                        }
                    }
                } else if dragging {
                    dragging = false
                    Log.line("mouse released, drag over")
                    onDragEnd?()
                }
                // Faster only while the button is down.
                try? await Task.sleep(for: .milliseconds(mouseDown ? 50 : 250))
            }
        }
    }

    /// Q2b: global monitor for left-mouse-dragged events. Reads trust without prompting.
    func startGlobalMonitor() {
        Log.line("AXIsProcessTrusted (no prompt) = \(AXIsProcessTrusted())")
        Log.line("CGPreflightListenEventAccess (no prompt) = \(CGPreflightListenEventAccess())")
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.dragEventsThisSecond += 1
                self?.dragEventsTotal += 1
            }
        }
        Log.line("global leftMouseDragged monitor installed = \(monitor != nil)")
        reportTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if self.dragEventsThisSecond > 0 {
                    Log.line("global leftMouseDragged events last second: \(self.dragEventsThisSecond) (total \(self.dragEventsTotal))")
                    self.dragEventsThisSecond = 0
                }
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        reportTask?.cancel()
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
