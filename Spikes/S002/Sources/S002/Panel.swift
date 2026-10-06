import AppKit

/// Borderless, non-activating panel that never becomes key or main.
/// Copied from S-001 and adapted: collection behavior is a parameter, clicks are reported.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// AppKit pushes a window below the menu bar on setFrame. Keep the frame as asked.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    init(frame: NSRect, level: NSWindow.Level, behavior: NSWindow.CollectionBehavior, onClick: @escaping @MainActor () -> Void) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = level
        isFloatingPanel = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = behavior
        contentView = Self.makeContent(onClick: onClick)
    }

    private static func makeContent(onClick: @escaping @MainActor () -> Void) -> NSView {
        let view = ClickView()
        view.onClick = onClick
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(white: 0.05, alpha: 1).cgColor
        view.layer?.borderColor = NSColor.systemGreen.cgColor
        view.layer?.borderWidth = 1

        let label = NSTextField(labelWithString: "S-002")
        label.textColor = .white
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        return view
    }
}

/// Reports a click without taking focus.
final class ClickView: NSView {
    var onClick: (@MainActor () -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

enum LevelChoice: String, CaseIterable {
    case mainMenu, statusBar, popUpMenu, screenSaver

    var level: NSWindow.Level {
        switch self {
        case .mainMenu: return .mainMenu
        case .statusBar: return .statusBar
        case .popUpMenu: return .popUpMenu
        case .screenSaver: return .screenSaver
        }
    }
}

enum BehaviorChoice: String {
    case base, spacesOnly, stationary

    var behavior: NSWindow.CollectionBehavior {
        switch self {
        case .base: return [.canJoinAllSpaces, .fullScreenAuxiliary]
        case .spacesOnly: return [.canJoinAllSpaces]
        case .stationary: return [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        }
    }
}
