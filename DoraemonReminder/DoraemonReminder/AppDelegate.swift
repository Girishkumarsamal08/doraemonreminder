import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var popoverViewController: ReminderPopoverViewController!
    private var eventMonitor: Any?
    
    // MARK: - App Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce single instance
        let bundleId = Bundle.main.bundleIdentifier ?? "com.girishkumarsamal.DoraemonReminder"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        if runningApps.count > 1 {
            for app in runningApps where app != NSRunningApplication.current {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        }
        
        // Hide dock icon and run as menu bar accessory
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        statusItem.autosaveName = "DoraemonReminderStatusItem"
        
        if let button = statusItem.button {
            button.toolTip = "Doraemon Reminder"
            
            // Load custom Doraemon Bell icon from resource bundle or asset catalog
            var iconImage: NSImage?
            if let resourcePath = Bundle.main.resourcePath {
                let paths = [
                    "\(resourcePath)/menuBarIcon@2x.png",
                    "\(resourcePath)/menuBarIcon.png",
                    "\(resourcePath)/doraemon_bell@2x.png",
                    "\(resourcePath)/doraemon_bell.png",
                    "\(resourcePath)/doraemon _bell.png"
                ]
                for path in paths {
                    if FileManager.default.fileExists(atPath: path), let img = NSImage(contentsOfFile: path) {
                        iconImage = img
                        break
                    }
                }
            }
            if iconImage == nil {
                iconImage = NSImage(named: "menuBarIcon") ?? NSImage(named: "doraemon_bell")
            }
            
            if let icon = iconImage {
                icon.isTemplate = false // Keep authentic Doraemon yellow bell colors
                icon.size = NSSize(width: 18, height: 18)
                button.image = icon
                button.imagePosition = .imageOnly
            } else if let sfBell = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Doraemon Reminder") {
                sfBell.isTemplate = true
                button.image = sfBell
                button.imagePosition = .imageOnly
            } else {
                button.title = "🔔"
            }
            
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup popover
        popoverViewController = ReminderPopoverViewController()
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 450)
        popover.behavior = .transient
        popover.contentViewController = popoverViewController
        popover.animates = true
        
        // Monitor for clicks outside the popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
        
        // Auto-show popover immediately on launch so the user sees the board right away
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showPopover()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
    
    // MARK: - App Reopen Handler (Finder / Launchpad / Spotlight)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        togglePopover()
        return true
    }
    
    // MARK: - Popover Actions
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
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
