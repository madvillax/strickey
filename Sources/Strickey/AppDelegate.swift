import AppKit
import Carbon
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Duplicate launches should not create another listener or audio graph.
    private lazy var model = AppModel()
    private var statusItem: NSStatusItem?
    private var controlsPopover: NSPopover?
    private var stateSubscription: AnyCancellable?
    private var workspaceObservers: [NSObjectProtocol] = []
    private var previewWindow: NSWindow?
    private var ready = false
    private var presentationRequested = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let current = NSRunningApplication.current
        if let identifier = Bundle.main.bundleIdentifier,
           let existing = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .filter({ !$0.isTerminated && Self.startedBefore($0, current) })
            .min(by: Self.startedBefore),
           let url = existing.bundleURL {
            // A real reopen AppleEvent reveals the existing panel. Activation alone does not.
            // Only the newer process exits, preventing two simultaneous launches killing each other.
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            configuration.createsNewApplicationInstance = false
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { [weak self] _, error in
                Task { @MainActor [weak self] in
                    if error != nil, existing.isTerminated {
                        self?.finishLaunching()
                    } else {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            return
        }
        finishLaunching()
    }

    private static func startedBefore(_ lhs: NSRunningApplication, _ rhs: NSRunningApplication) -> Bool {
        guard lhs.processIdentifier != rhs.processIdentifier else { return false }
        if let left = lhs.launchDate, let right = rhs.launchDate, left != right { return left < right }
        return lhs.processIdentifier < rhs.processIdentifier
    }

    private func finishLaunching() {
        guard !ready else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        if let button = item.button {
            let image = Self.menuBarImage()
            button.image = image
            button.setAccessibilityLabel("strickey")
            button.target = self
            button.action = #selector(toggleControls)
            button.isEnabled = true
        }
        let hostingController = NSHostingController(rootView: MenuBarView(model: model))
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = hostingController
        popover.contentSize = hostingController.view.fittingSize
        controlsPopover = popover
        stateSubscription = model.$status.sink { [weak self] status in
            self?.statusItem?.button?.toolTip = "strickey — \(status.title)"
        }
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.sleep() }
        })
        workspaceObservers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.wake() }
        })
        model.start()
        ready = true
        if CommandLine.arguments.contains("--preview-window") {
            let view = NSHostingView(rootView: MenuBarView(model: model))
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: view.fittingSize),
                styleMask: [.titled, .closable], backing: .buffered, defer: false
            )
            window.title = "strickey — Development Preview"
            window.isOpaque = false
            window.backgroundColor = .clear
            window.contentView = view
            window.center()
            window.makeKeyAndOrderFront(nil)
            previewWindow = window
            NSApplication.shared.activate()
        } else if presentationRequested || !launchedInBackground {
            // Explicit launches always show controls; login launches stay quiet.
            requestPresentation()
        }
    }

    private static func menuBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()
            let outline = NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: 16, height: 16), xRadius: 3, yRadius: 3)
            outline.lineWidth = 1.2
            outline.stroke()
            let points: [(CGFloat, CGFloat)] = [(0, 0), (288, 0), (288, 80), (80, 80),
                (80, 128), (256, 128), (256, 288), (0, 288), (0, 208), (176, 208), (176, 160), (0, 160)]
            let mark = NSBezierPath()
            for (index, point) in points.enumerated() {
                let vertex = NSPoint(x: 4 + point.0 * 10 / 288, y: 14 - point.1 * 10 / 288)
                if index == 0 { mark.move(to: vertex) } else { mark.line(to: vertex) }
            }
            mark.close()
            NSColor.black.setFill()
            mark.fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    private var launchedInBackground: Bool {
        if CommandLine.arguments.contains("--background") { return true }
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication else { return false }
        return event.paramDescriptor(forKeyword: keyAELaunchedAsLogInItem)?.booleanValue == true
            || event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    @objc private func toggleControls() {
        if controlsPopover?.isShown == true { dismissControls() }
        else { requestPresentation() }
    }

    private func requestPresentation() {
        presentationRequested = true
        // NSPopover owns menu-bar anchoring and outside-click dismissal. Showing it
        // synchronously avoids the activation/focus race that could hide the old panel.
        guard ready, let button = statusItem?.button, let popover = controlsPopover else { return }
        presentationRequested = false
        guard !popover.isShown else { return }
        NSApplication.shared.unhide(nil)
        NSApplication.shared.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func dismissControls() {
        presentationRequested = false
        controlsPopover?.performClose(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let previewWindow, previewWindow.isVisible {
            previewWindow.makeKeyAndOrderFront(nil)
            sender.activate()
        } else {
            requestPresentation()
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        if ready { model.shutdown() }
        for observer in workspaceObservers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
    }
}
