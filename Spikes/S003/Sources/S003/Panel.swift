import AppKit

/// Borderless, non-activating panel that never becomes key or main.
/// Adapted from S-002: the content view is a drop target.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// AppKit pushes a window below the menu bar on setFrame. Keep the frame as asked.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    init(frame: NSRect, level: NSWindow.Level, behavior: NSWindow.CollectionBehavior, content: NSView) {
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
        contentView = content
    }
}

/// Drop target view. Reports drag events through closures and draws its own fill.
final class DropView: NSView {
    var onEnter: ((NSDraggingInfo) -> Void)?
    var onExit: (() -> Void)?
    var onDrop: ((NSDraggingInfo) -> Bool)?
    var onMouseDown: (() -> Void)?

    static let acceptedTypes: [NSPasteboard.PasteboardType] = [.fileURL, .URL, .tiff, .png, .string]

    init(fill: NSColor, border: NSColor?, label: String?) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = fill.cgColor
        if let border {
            layer?.borderColor = border.cgColor
            layer?.borderWidth = 1
        }
        if let label {
            let field = NSTextField(labelWithString: label)
            field.textColor = .white
            field.font = .systemFont(ofSize: 11, weight: .semibold)
            field.translatesAutoresizingMaskIntoConstraints = false
            addSubview(field)
            NSLayoutConstraint.activate([
                field.centerXAnchor.constraint(equalTo: centerXAnchor),
                field.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            ])
        }
        registerForDraggedTypes(Self.acceptedTypes)
    }

    required init?(coder: NSCoder) { nil }

    /// Reports a click that landed on this view (it then does not reach the window below).
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onEnter?(sender)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onExit?()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onDrop?(sender) ?? false
    }
}

enum LevelChoice: String {
    case statusBar, popUpMenu

    var level: NSWindow.Level {
        switch self {
        case .statusBar: return .statusBar
        case .popUpMenu: return .popUpMenu
        }
    }
}

enum BehaviorChoice: String {
    case base, stationary

    var behavior: NSWindow.CollectionBehavior {
        switch self {
        case .base: return [.canJoinAllSpaces, .fullScreenAuxiliary]
        case .stationary: return [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        }
    }
}
