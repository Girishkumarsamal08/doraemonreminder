import Cocoa

// MARK: - Status Bar Controller (Architecture identical to SpydyReminder)
class StatusBarController: NSObject, NSPopoverDelegate {
    var statusItem: NSStatusItem
    var popover: NSPopover
    var isPopoverClosing = false
    
    init(popover: NSPopover) {
        self.popover = popover
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        
        popover.delegate = self
        
        if let button = statusItem.button {
            button.toolTip = "Doraemon Reminder"
            
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            if let image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Doraemon Reminder")?.withSymbolConfiguration(config) {
                image.isTemplate = true
                button.image = image
                button.imagePosition = .imageOnly
            } else if let custom = NSImage(named: "menuBarIcon") {
                custom.isTemplate = true
                custom.size = NSSize(width: 18, height: 18)
                button.image = custom
            } else {
                button.title = "🔔"
            }
            
            button.target = self
            button.action = #selector(togglePopover(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc func togglePopover(sender: AnyObject?) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hidePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    func popoverDidClose(_ notification: Notification) {
        isPopoverClosing = false
    }
}

// MARK: - App Delegate
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController!
    private var popover: NSPopover!
    private var popoverViewController: ReminderPopoverViewController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance
        let bundleId = Bundle.main.bundleIdentifier ?? "com.girishkumarsamal.DoraemonReminder"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        for app in runningApps where app != NSRunningApplication.current {
            app.terminate()
        }
        
        // Hide dock icon and run purely as menu bar accessory
        NSApp.setActivationPolicy(.accessory)
        
        // Setup popover board
        popoverViewController = ReminderPopoverViewController()
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = popoverViewController
        
        // Setup Status Bar controller
        statusBarController = StatusBarController(popover: popover)
        
        // Auto-show popover board on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.statusBarController.showPopover(nil)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusBarController.showPopover(nil)
        return true
    }
}
