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
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            // Use the menu bar icon from assets, or fallback to emoji
            if let menuIcon = NSImage(named: "menuBarIcon") {
                menuIcon.isTemplate = true
                menuIcon.size = NSSize(width: 18, height: 18)
                button.image = menuIcon
            } else {
                button.title = "🔔"
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup popover
        popoverViewController = ReminderPopoverViewController()
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.contentViewController = popoverViewController
        popover.animates = true
        
        // Monitor for clicks outside the popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
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
