import AppKit
import ApplicationServices
import Carbon.HIToolbox

/// Shared toggle action. Both hotkey methods deliver on the main thread.
@MainActor
enum HotkeyRouter {
    static var onToggle: (() -> Void)?
}

/// Method 1: Carbon RegisterEventHotKey, Control+Option+Command+L.
@MainActor
final class CarbonHotkey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register() -> OSStatus {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, _, _ in
            // Carbon calls application-target handlers on the main thread.
            MainActor.assumeIsolated { HotkeyRouter.onToggle?() }
            return noErr
        }
        var status = InstallEventHandler(GetApplicationEventTarget(), handler, 1, &spec, nil, &handlerRef)
        guard status == noErr else { return status }

        let id = EventHotKeyID(signature: OSType(0x5331_3031), id: 1) // "S101"
        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        status = RegisterEventHotKey(UInt32(kVK_ANSI_L), modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef)
        return status
    }

    func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
        hotKeyRef = nil
        handlerRef = nil
    }
}

/// Method 2: NSEvent global monitor for keyDown.
@MainActor
final class GlobalMonitorHotkey {
    private var monitor: Any?

    /// Reads trust state without asking the system to show a prompt.
    static var isTrusted: Bool { AXIsProcessTrusted() }

    func register() -> Bool {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let wanted: NSEvent.ModifierFlags = [.control, .option, .command]
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard event.keyCode == UInt16(kVK_ANSI_L), flags == wanted else { return }
            MainActor.assumeIsolated { HotkeyRouter.onToggle?() }
        }
        return monitor != nil
    }

    func unregister() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
