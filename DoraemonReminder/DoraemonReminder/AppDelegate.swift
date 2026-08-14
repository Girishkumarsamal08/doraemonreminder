import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var popoverViewController: ReminderPopoverViewController!
    
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
        
        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.toolTip = "Doraemon Reminder"
            
            // Load template bell icon
            var icon: NSImage?
            if let resourcePath = Bundle.main.resourcePath {
                let paths = [
                    "\(resourcePath)/menuBarIcon@2x.png",
                    "\(resourcePath)/menuBarIcon.png",
                    "\(resourcePath)/doraemon_bell@2x.png",
                    "\(resourcePath)/doraemon_bell.png"
                ]
                for path in paths {
                    if FileManager.default.fileExists(atPath: path), let img = NSImage(contentsOfFile: path) {
                        icon = img
                        break
                    }
                }
            }
            if icon == nil {
                icon = NSImage(named: "menuBarIcon")
            }
            if icon == nil {
                icon = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Doraemon Reminder")
            }
            
            if let icon = icon {
                icon.isTemplate = true // macOS native auto-tint (crisp white in dark mode, charcoal in light mode)
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
    @objc private func showPopover() {
        guard let button = statusItem?.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
