import Cocoa

class DropAnimationWindowController: NSObject {
    
    private var overlayWindow: NSWindow?
    private var doraemonImageView: NSImageView?
    private var messageLabel: NSTextField?
    private var bubbleView: NSView?
    private let message: String
    private var localEventMonitor: Any?
    private var escEventMonitor: Any?
    
    init(message: String) {
        self.message = message
        super.init()
    }
    
    func showDrop() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        // Create fullscreen transparent overlay window
        overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        guard let window = overlayWindow else { return }
        
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = NSView(frame: screenFrame)
        contentView.wantsLayer = true
        window.contentView = contentView
        
        // ── Doraemon Image ──
        let doraemonSize: CGFloat = 200
        let centerX = screenFrame.width / 2 - doraemonSize / 2
        let startY = screenFrame.height + doraemonSize // Start above the screen
        let targetY = screenFrame.height / 2 + 30      // Land in center-ish
        
        let imageView = NSImageView(frame: NSRect(x: centerX, y: startY, width: doraemonSize, height: doraemonSize))
        
        // Try to load from bundle first, then from file
        if let bundleImage = NSImage(named: "doraemon") {
            imageView.image = bundleImage
        } else {
            // Fallback: try to load from the app's resource path
            let possiblePaths = [
                Bundle.main.resourcePath.map { "\($0)/doraemon.webp" },
                Bundle.main.resourcePath.map { "\($0)/doraemon.png" }
            ].compactMap { $0 }
            
            for path in possiblePaths {
                if let img = NSImage(contentsOfFile: path) {
                    imageView.image = img
                    break
                }
            }
        }
        
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.shadowColor = NSColor(red: 0, green: 0.59, blue: 0.84, alpha: 0.6).cgColor
        imageView.layer?.shadowOffset = CGSize(width: 0, height: -10)
        imageView.layer?.shadowRadius = 30
        imageView.layer?.shadowOpacity = 1.0
        contentView.addSubview(imageView)
        doraemonImageView = imageView
        
        // ── Speech Bubble ──
        let bubbleWidth: CGFloat = 280
        let bubbleHeight: CGFloat = 60
        let bubbleX = centerX + doraemonSize / 2 - bubbleWidth / 2
        let bubbleY = targetY - bubbleHeight - 15
        
        let bubble = NSView(frame: NSRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight))
        bubble.wantsLayer = true
        bubble.layer?.backgroundColor = NSColor.white.cgColor
        bubble.layer?.cornerRadius = 16
        bubble.layer?.shadowColor = NSColor.black.withAlphaComponent(0.2).cgColor
        bubble.layer?.shadowOffset = CGSize(width: 0, height: -4)
        bubble.layer?.shadowRadius = 15
        bubble.layer?.shadowOpacity = 1.0
        bubble.alphaValue = 0
        
        let msgLabel = NSTextField(labelWithString: message)
        msgLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        msgLabel.textColor = NSColor(red: 0.17, green: 0.17, blue: 0.15, alpha: 1.0)
        msgLabel.alignment = .center
        msgLabel.frame = NSRect(x: 15, y: 10, width: bubbleWidth - 30, height: bubbleHeight - 20)
        msgLabel.lineBreakMode = .byTruncatingTail
        msgLabel.maximumNumberOfLines = 2
        bubble.addSubview(msgLabel)
        
        contentView.addSubview(bubble)
        bubbleView = bubble
        messageLabel = msgLabel
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // ── Animate Drop ──
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            imageView.animator().frame = NSRect(x: centerX, y: targetY, width: doraemonSize, height: doraemonSize)
        }, completionHandler: { [weak self] in
            // Show bubble with fade-in after Doraemon lands
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                self?.bubbleView?.animator().alphaValue = 1.0
            })
            
            // Add a gentle bobbing animation
            self?.startBobbingAnimation()
        })
        
        // ── Dismiss on click ──
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.dismissDrop()
            return event
        }
        
        // ── Dismiss on ESC ──
        escEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.dismissDrop()
                return nil
            }
            return event
        }
        
        // Auto-dismiss after 15 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.dismissDrop()
        }
    }
    
    private func startBobbingAnimation() {
        guard let imageView = doraemonImageView else { return }
        
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = imageView.layer?.position.y ?? 0
        animation.toValue = (imageView.layer?.position.y ?? 0) + 10
        animation.duration = 1.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        imageView.layer?.add(animation, forKey: "bobbing")
    }
    
    private func dismissDrop() {
        // Remove event monitors
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = escEventMonitor {
            NSEvent.removeMonitor(monitor)
            escEventMonitor = nil
        }
        
        // Animate out
        NSAnimationContext.runAnimationGroup({ [weak self] context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self?.overlayWindow?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.overlayWindow?.orderOut(nil)
            self?.overlayWindow = nil
        })
    }
}
