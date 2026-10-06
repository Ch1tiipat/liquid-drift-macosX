import AppKit

/// Borderless, non-activating panel that never becomes key or main.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// AppKit pushes a window below the menu bar on setFrame. Keep the frame as asked.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    init(frame: NSRect, level: NSWindow.Level) {
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
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = Self.makeContent()
    }

    private static func makeContent() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(white: 0.05, alpha: 1).cgColor
        view.layer?.borderColor = NSColor.systemGreen.cgColor
        view.layer?.borderWidth = 1

        let label = NSTextField(labelWithString: "S-001")
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

enum LevelChoice: String, CaseIterable {
    case mainMenu, statusBar, popUpMenu, screenSaver, custom

    var level: NSWindow.Level {
        switch self {
        case .mainMenu: return .mainMenu
        case .statusBar: return .statusBar
        case .popUpMenu: return .popUpMenu
        case .screenSaver: return .screenSaver
        // .statusBar is mainMenu + 1, so the custom value skips one more step.
        case .custom: return NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 2)
        }
    }
}
