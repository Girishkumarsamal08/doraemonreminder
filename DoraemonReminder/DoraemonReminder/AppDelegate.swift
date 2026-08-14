import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var popoverViewController: ReminderPopoverViewController!
    
    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance: terminate duplicate instances
        let bundleId = Bundle.main.bundleIdentifier ?? "com.girishkumarsamal.DoraemonReminder"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        for app in runningApps where app != NSRunningApplication.current {
            app.terminate()
        }
        
        // Hide dock icon and run purely as menu bar accessory
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item with squareLength
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.toolTip = "Doraemon Reminder"
            
            // Prefer native SF Symbol bell for guaranteed system rendering
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            var icon = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Doraemon Reminder")?.withSymbolConfiguration(config)
            
            if icon == nil, let customImg = NSImage(named: "menuBarIcon") {
                icon = customImg
            }
            
            if let icon = icon {
                icon.isTemplate = true
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
                button.imagePosition = .imageOnly
            } else {
                button.title = "🔔"
            }
            
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup popover board
        popoverViewController = ReminderPopoverViewController()
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.contentViewController = popoverViewController
        popover.animates = true
        
        // Auto-show popover board on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showPopover()
        }
    }
    
    // MARK: - App Reopen Handler (Finder / Launchpad / Spotlight)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPopover()
        return true
    }
    
    // MARK: - Popover Actions
    @objc func showPopover() {
        guard let button = statusItem?.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
