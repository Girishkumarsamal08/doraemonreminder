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
        // Hide dock icon and run as menu bar accessory
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.toolTip = "Doraemon Reminder"
            
            // Load custom Doraemon Bell icon from resource bundle or asset catalog
            var iconImage: NSImage?
            if let resourcePath = Bundle.main.resourcePath {
                let paths = [
                    "\(resourcePath)/doraemon_bell@2x.png",
                    "\(resourcePath)/doraemon_bell.png",
                    "\(resourcePath)/menuBarIcon@2x.png",
                    "\(resourcePath)/menuBarIcon.png",
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
                icon.isTemplate = false // Keep the authentic colorful Doraemon yellow bell
                icon.size = NSSize(width: 20, height: 20)
                button.image = icon
            } else if let sfBell = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Doraemon Reminder") {
                sfBell.isTemplate = true
                button.image = sfBell
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
        
        // Auto-show popover briefly on launch so user sees the app on their menu bar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let button = self?.statusItem.button, let popover = self?.popover, !popover.isShown {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
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
    
    // MARK: - Popover Toggle
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
