import AppKit
import PathConverterCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, FloatingPanelControllerDelegate {
    private let configStore = ConfigStore()
    private var config = PathConverterConfig()
    private var converter = PathConverter(mappings: PathMapping.defaults)
    private var panelController: FloatingPanelController?
    private var statusItem: NSStatusItem?
    private var pasteboardTimer: Timer?
    private var pasteboardTracker = PasteboardChangeTracker(initialChangeCount: NSPasteboard.general.changeCount)
    private var lastPresentedSignature: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateDuplicateInstances()
        reloadConfig()
        setupStatusItem()
        panelController = FloatingPanelController(delegate: self)
        installPasteboardPolling()
    }

    func applicationWillTerminate(_ notification: Notification) {
        pasteboardTimer?.invalidate()
    }

    func floatingPanelDidRequestCopy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        pasteboardTracker.acknowledge(currentChangeCount: NSPasteboard.general.changeCount)
        panelController?.hide()
    }

    func floatingPanelDidRequestOpen(_ path: String) {
        openFolder(for: path)
        panelController?.hide()
    }

    func floatingPanelDidRequestReverse(_ source: String) -> ConversionResult? {
        converter.convertMacToWindows(source)
    }

    @objc private func checkClipboardNow() {
        inspectClipboard(force: true)
    }

    @objc private func reloadConfigFromMenu() {
        reloadConfig()
    }

    @objc private func openConfigFile() {
        _ = configStore.load()
        NSWorkspace.shared.open(configStore.url)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "⇄"
        item.button?.toolTip = "Path Converter"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Check Clipboard Now", action: #selector(checkClipboardNow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Config", action: #selector(openConfigFile), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reload Config", action: #selector(reloadConfigFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Path Converter", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    private func terminateDuplicateInstances() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        for application in NSRunningApplication.runningApplications(withBundleIdentifier: "local.pathconverter")
        where application.processIdentifier != currentPID {
            application.terminate()
        }
    }

    private func reloadConfig() {
        config = configStore.load()
        converter = PathConverter(mappings: config.mappings)
    }

    private func installPasteboardPolling() {
        pasteboardTimer?.invalidate()
        pasteboardTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.inspectClipboardIfChanged()
            }
        }
    }

    private func inspectClipboardIfChanged() {
        let currentChangeCount = NSPasteboard.general.changeCount
        guard pasteboardTracker.shouldInspect(currentChangeCount: currentChangeCount) else { return }
        inspectClipboard(force: false)
    }

    private func inspectClipboard(force: Bool) {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        if let result = converter.detectWindowsPath(in: text) {
            present(result, force: force)
            return
        }

        if let prompt = converter.detectMacPathPrompt(text) {
            present(prompt, force: force)
        }
    }

    private func present(_ result: ConversionResult, force: Bool) {
        let signature = "\(result.direction)-\(result.source)-\(result.converted ?? "")"
        guard force || signature != lastPresentedSignature || panelController?.isVisible != true else {
            return
        }

        lastPresentedSignature = signature
        panelController?.show(result)
    }

    private func openFolder(for path: String) {
        let url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)

        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            let folder = isDirectory.boolValue ? url : url.deletingLastPathComponent()
            NSWorkspace.shared.open(folder)
            return
        }

        let inferredFolder = url.pathExtension.isEmpty ? url : url.deletingLastPathComponent()
        NSWorkspace.shared.open(inferredFolder)
    }
}
