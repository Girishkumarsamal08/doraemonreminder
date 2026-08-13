import Cocoa

class DropAnimationWindowController: NSObject {
    
    private var overlayWindow: NSWindow?
    private var doraemonImageView: NSImageView?
    private var messageLabel: NSTextField?
    private var bubbleView: NSView?
    private let message: String
    private var localEventMonitor: Any?
    private var escEventMonitor: Any?
    private var isDismissing = false
    
    init(message: String) {
        self.message = message.isEmpty ? "Time for your reminder!" : message
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
        window.backgroundColor = NSColor.black.withAlphaComponent(0.35)
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = NSView(frame: screenFrame)
        contentView.wantsLayer = true
        window.contentView = contentView
        
        // ── Doraemon Image Setup ──
        let doraemonWidth: CGFloat = 220
        let doraemonHeight: CGFloat = 220
        let startX: CGFloat = -doraemonWidth - 50 // Start off-screen to the left
        let centerScreenX: CGFloat = screenFrame.width / 2 - doraemonWidth / 2
        let flyY: CGFloat = screenFrame.height / 2 + 20
        
        let imageView = NSImageView(frame: NSRect(x: startX, y: flyY, width: doraemonWidth, height: doraemonHeight))
        
        // Try to load bundle asset first, then resource folder
        if let bundleImage = NSImage(named: "doraemon") {
            imageView.image = bundleImage
        } else {
            let possiblePaths = [
                Bundle.main.resourcePath.map { "\($0)/doraemon.webp" },
                Bundle.main.resourcePath.map { "\($0)/images/doraemon.webp" },
                Bundle.main.resourcePath.map { "\($0)/doraemon face.jpg" },
                Bundle.main.resourcePath.map { "\($0)/images/doraemon face.jpg" }
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
        imageView.layer?.shadowColor = NSColor(red: 0, green: 0.59, blue: 0.84, alpha: 0.7).cgColor
        imageView.layer?.shadowOffset = CGSize(width: 0, height: -8)
        imageView.layer?.shadowRadius = 25
        imageView.layer?.shadowOpacity = 1.0
        contentView.addSubview(imageView)
        doraemonImageView = imageView
        
        // ── Speech Bubble Setup ──
        let bubbleWidth: CGFloat = max(300, min(CGFloat(message.count * 11 + 60), 480))
        let bubbleHeight: CGFloat = 68
        let bubbleX = centerScreenX + doraemonWidth / 2 - bubbleWidth / 2
        let bubbleY = flyY - bubbleHeight - 18
        
        let bubble = NSView(frame: NSRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight))
        bubble.wantsLayer = true
        bubble.layer?.backgroundColor = NSColor(red: 0.12, green: 0.14, blue: 0.18, alpha: 0.95).cgColor
        bubble.layer?.borderColor = NSColor(red: 0, green: 0.59, blue: 0.84, alpha: 0.5).cgColor
        bubble.layer?.borderWidth = 1.5
        bubble.layer?.cornerRadius = 18
        bubble.layer?.shadowColor = NSColor.black.withAlphaComponent(0.4).cgColor
        bubble.layer?.shadowOffset = CGSize(width: 0, height: -6)
        bubble.layer?.shadowRadius = 20
        bubble.layer?.shadowOpacity = 1.0
        bubble.alphaValue = 0
        
        let bellIcon = NSTextField(labelWithString: "🔔")
        bellIcon.font = NSFont.systemFont(ofSize: 22)
        bellIcon.frame = NSRect(x: 14, y: (bubbleHeight - 28) / 2, width: 30, height: 28)
        bubble.addSubview(bellIcon)
        
        let msgLabel = NSTextField(labelWithString: message)
        msgLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        msgLabel.textColor = .white
        msgLabel.alignment = .left
        msgLabel.frame = NSRect(x: 48, y: 12, width: bubbleWidth - 62, height: bubbleHeight - 24)
        msgLabel.lineBreakMode = .byTruncatingTail
        msgLabel.maximumNumberOfLines = 2
        bubble.addSubview(msgLabel)
        
        contentView.addSubview(bubble)
        bubbleView = bubble
        messageLabel = msgLabel
        
        // Show window and bring to front
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Play notification chime
        NSSound(named: "Glass")?.play()
        
        // ── Step 1: Fly Doraemon from Left Edge to Center ──
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.0
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            imageView.animator().frame = NSRect(x: centerScreenX, y: flyY, width: doraemonWidth, height: doraemonHeight)
        }, completionHandler: { [weak self] in
            guard let self = self, !self.isDismissing else { return }
            
            // Fade in and pop the speech bubble
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.35
                self.bubbleView?.animator().alphaValue = 1.0
            })
            
            // Start gentle bobbing/hovering while delivering message
            self.startHoverAnimation()
            
            // Auto dismiss and fly to the right after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.flyOutToRight()
            }
        })
        
        // ── Dismiss on click ──
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.flyOutToRight()
            return event
        }
        
        // ── Dismiss on ESC key ──
        escEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.flyOutToRight()
                return nil
            }
            return event
        }
    }
    
    private func startHoverAnimation() {
        guard let imageView = doraemonImageView else { return }
        
        let hover = CABasicAnimation(keyPath: "position.y")
        hover.fromValue = imageView.layer?.position.y ?? 0
        hover.toValue = (imageView.layer?.position.y ?? 0) + 12
        hover.duration = 1.2
        hover.autoreverses = true
        hover.repeatCount = .infinity
        hover.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        imageView.layer?.add(hover, forKey: "hover")
    }
    
    // ── Step 2: Fly Out to the Right Screen Edge ──
    private func flyOutToRight() {
        guard !isDismissing else { return }
        isDismissing = true
        
        // Remove monitors
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = escEventMonitor {
            NSEvent.removeMonitor(monitor)
            escEventMonitor = nil
        }
        
        guard let screen = NSScreen.main, let imageView = doraemonImageView else {
            cleanup()
            return
        }
        
        let screenWidth = screen.frame.width
        let endX = screenWidth + 300 // Off the right edge
        let currentY = imageView.frame.origin.y
        let width = imageView.frame.width
        let height = imageView.frame.height
        
        // Remove hover animation
        imageView.layer?.removeAnimation(forKey: "hover")
        
        // Fade out speech bubble
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            self.bubbleView?.animator().alphaValue = 0
            self.overlayWindow?.animator().alphaValue = 0.5
        })
        
        // Accelerate and fly Doraemon off to the right
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.8
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            imageView.animator().frame = NSRect(x: endX, y: currentY + 40, width: width, height: height)
        }, completionHandler: { [weak self] in
            self?.cleanup()
        })
    }
    
    private func cleanup() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        doraemonImageView = nil
        bubbleView = nil
        messageLabel = nil
    }
}

