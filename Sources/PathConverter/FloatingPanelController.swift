import AppKit
import PathConverterCore

@MainActor
protocol FloatingPanelControllerDelegate: AnyObject {
    func floatingPanelDidRequestCopy(_ text: String)
    func floatingPanelDidRequestOpen(_ path: String)
    func floatingPanelDidRequestReverse(_ source: String) -> ConversionResult?
}

@MainActor
final class FloatingPanelController: NSObject {
    private weak var delegate: FloatingPanelControllerDelegate?
    private let panel: NSPanel
    private let titleLabel = NSTextField(labelWithString: "")
    private let sourceLabel = NSTextField(labelWithString: "")
    private let outputLabel = NSTextField(labelWithString: "")
    private let mappingLabel = NSTextField(labelWithString: "")
    private let copyButton = NSButton(title: "Copy", target: nil, action: nil)
    private let openButton = NSButton(title: "Open Folder", target: nil, action: nil)
    private let reverseButton = NSButton(title: "Convert to Windows", target: nil, action: nil)
    private let closeButton = NSButton(title: "×", target: nil, action: nil)
    private var currentResult: ConversionResult?
    private var dismissWorkItem: DispatchWorkItem?

    var isVisible: Bool {
        panel.isVisible
    }

    init(delegate: FloatingPanelControllerDelegate) {
        self.delegate = delegate
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 178),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()
        setupPanel()
        setupContent()
    }

    func show(_ result: ConversionResult) {
        currentResult = result
        render(result)
        positionNearMouse()
        scheduleDismiss(after: result.direction == .macPrompt ? 7 : 10)

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        dismissWorkItem?.cancel()
        guard panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.10
            panel.animator().alphaValue = 0
        } completionHandler: {
            self.panel.orderOut(nil)
            self.panel.alphaValue = 1
        }
    }

    @objc private func copyConvertedPath() {
        guard let text = currentResult?.converted else { return }
        delegate?.floatingPanelDidRequestCopy(text)
    }

    @objc private func openFolder() {
        guard let path = currentResult?.converted else { return }
        delegate?.floatingPanelDidRequestOpen(path)
    }

    @objc private func reverse() {
        guard let source = currentResult?.source,
              let result = delegate?.floatingPanelDidRequestReverse(source)
        else {
            NSSound.beep()
            return
        }

        currentResult = result
        render(result)
        scheduleDismiss(after: 10)
    }

    @objc private func close() {
        hide()
    }

    private func setupPanel() {
        panel.level = .floating
        panel.collectionBehavior = [.transient, .moveToActiveSpace, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
    }

    private func setupContent() {
        let blurView = NSVisualEffectView()
        blurView.material = .hudWindow
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 12
        blurView.layer?.masksToBounds = true

        panel.contentView = blurView

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor

        sourceLabel.font = .systemFont(ofSize: 11)
        sourceLabel.textColor = .secondaryLabelColor
        sourceLabel.lineBreakMode = .byTruncatingMiddle

        outputLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        outputLabel.textColor = .labelColor
        outputLabel.lineBreakMode = .byTruncatingMiddle
        outputLabel.isSelectable = true

        mappingLabel.font = .systemFont(ofSize: 11)
        mappingLabel.textColor = .tertiaryLabelColor

        [copyButton, openButton, reverseButton].forEach { button in
            button.bezelStyle = .rounded
            button.controlSize = .small
        }
        copyButton.target = self
        copyButton.action = #selector(copyConvertedPath)
        openButton.target = self
        openButton.action = #selector(openFolder)
        reverseButton.target = self
        reverseButton.action = #selector(reverse)

        closeButton.target = self
        closeButton.action = #selector(close)
        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.font = .systemFont(ofSize: 16, weight: .medium)

        let header = NSStackView(views: [titleLabel, NSView(), closeButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 8

        let outputBox = NSBox()
        outputBox.boxType = .custom
        outputBox.cornerRadius = 7
        outputBox.borderColor = NSColor.separatorColor.withAlphaComponent(0.55)
        outputBox.fillColor = NSColor.textBackgroundColor.withAlphaComponent(0.28)
        outputBox.contentViewMargins = NSSize(width: 10, height: 7)
        outputBox.contentView = outputLabel

        let buttons = NSStackView(views: [copyButton, openButton, reverseButton])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 8

        let stack = NSStackView(views: [header, sourceLabel, outputBox, mappingLabel, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false

        blurView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: blurView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            outputBox.widthAnchor.constraint(equalToConstant: 392),
            outputBox.heightAnchor.constraint(equalToConstant: 38),
            buttons.heightAnchor.constraint(equalToConstant: 26),
            closeButton.widthAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func render(_ result: ConversionResult) {
        sourceLabel.stringValue = "In: \(result.source)"
        mappingLabel.stringValue = result.mappingLabel

        switch result.direction {
        case .windowsToMac:
            titleLabel.stringValue = "Windows path"
            outputLabel.stringValue = result.converted ?? ""
            copyButton.isHidden = false
            openButton.isHidden = false
            reverseButton.isHidden = true
        case .macPrompt:
            titleLabel.stringValue = "Mac path"
            outputLabel.stringValue = "Convert only when you ask"
            copyButton.isHidden = true
            openButton.isHidden = true
            reverseButton.isHidden = false
        case .macToWindows:
            titleLabel.stringValue = "Windows path"
            outputLabel.stringValue = result.converted ?? ""
            copyButton.isHidden = false
            openButton.isHidden = true
            reverseButton.isHidden = true
        }
    }

    private func positionNearMouse() {
        let size = panel.frame.size
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.visibleFrame.contains(mouse) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var origin = NSPoint(x: mouse.x + 16, y: mouse.y - size.height - 16)

        if origin.x + size.width > visibleFrame.maxX {
            origin.x = visibleFrame.maxX - size.width - 12
        }
        if origin.y < visibleFrame.minY {
            origin.y = mouse.y + 16
        }
        if origin.y + size.height > visibleFrame.maxY {
            origin.y = visibleFrame.maxY - size.height - 12
        }
        if origin.x < visibleFrame.minX {
            origin.x = visibleFrame.minX + 12
        }

        panel.setFrameOrigin(origin)
    }

    private func scheduleDismiss(after seconds: TimeInterval) {
        dismissWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }
}
