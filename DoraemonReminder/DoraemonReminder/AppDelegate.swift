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
            
            var icon: NSImage?
            if let resourcePath = Bundle.main.resourcePath {
                let paths = [
                    "\(resourcePath)/doraemon_bell_clean@2x.png",
                    "\(resourcePath)/doraemon_bell_clean.png",
                    "\(resourcePath)/doraemon_bell@2x.png",
                    "\(resourcePath)/doraemon_bell.png",
                    "\(resourcePath)/menuBarIcon@2x.png",
                    "\(resourcePath)/menuBarIcon.png"
                ]
                for path in paths {
                    if FileManager.default.fileExists(atPath: path), let img = NSImage(contentsOfFile: path) {
                        icon = img
                        break
                    }
                }
            }
            if icon == nil {
                icon = NSImage(named: "menuBarIcon") ?? NSImage(named: "doraemon_bell_clean")
            }
            
            if let icon = icon {
                icon.isTemplate = false // Keep the colorful Doraemon Bell
                icon.size = NSSize(width: 20, height: 20)
                button.image = icon
                button.imageScaling = .scaleProportionallyDown
                button.imagePosition = .imageOnly
            } else {
                let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
                if let sfBell = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Doraemon Reminder")?.withSymbolConfiguration(config) {
                    sfBell.isTemplate = true
                    button.image = sfBell
                    button.imagePosition = .imageOnly
                } else {
                    button.title = "🔔"
                }
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
