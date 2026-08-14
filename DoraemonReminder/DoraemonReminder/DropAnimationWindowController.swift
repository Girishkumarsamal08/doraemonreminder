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
    private var autoDismissTimer: Timer?
    
    init(message: String) {
        self.message = message.isEmpty ? "Time for your reminder!" : message
        super.init()
    }
    
    func showDrop() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        // Fullscreen transparent overlay window
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
        
        // ── Dimensions ──
        let doraemonSize: CGFloat = 220
        let startLeftX: CGFloat = -doraemonSize - 60 // Off-screen left
        let centerScreenX: CGFloat = (screenFrame.width - doraemonSize) / 2
        let flyY: CGFloat = screenFrame.height / 2 + 30
        
        // ── Doraemon Character ImageView ──
        let imageView = NSImageView(frame: NSRect(x: startLeftX, y: flyY, width: doraemonSize, height: doraemonSize))
        imageView.image = loadDoraemonImage()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.shadowColor = NSColor(red: 0, green: 0.59, blue: 0.84, alpha: 0.75).cgColor
        imageView.layer?.shadowOffset = CGSize(width: 0, height: -6)
        imageView.layer?.shadowRadius = 24
        imageView.layer?.shadowOpacity = 1.0
        contentView.addSubview(imageView)
        doraemonImageView = imageView
        
        // ── Letter / Message Card Setup (Styled like pulling a reminder from 4D Pocket) ──
        let bubbleWidth: CGFloat = max(320, min(CGFloat(message.count * 11 + 80), 500))
        let bubbleHeight: CGFloat = 72
        let bubbleX = (screenFrame.width - bubbleWidth) / 2
        let bubbleY = flyY - bubbleHeight - 16
        
        let bubble = NSView(frame: NSRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight))
        bubble.wantsLayer = true
        bubble.layer?.backgroundColor = NSColor(red: 0.11, green: 0.13, blue: 0.18, alpha: 0.96).cgColor
        bubble.layer?.borderColor = NSColor(red: 0.0, green: 0.59, blue: 0.84, alpha: 0.7).cgColor
        bubble.layer?.borderWidth = 1.5
        bubble.layer?.cornerRadius = 16
        bubble.layer?.shadowColor = NSColor.black.withAlphaComponent(0.5).cgColor
        bubble.layer?.shadowOffset = CGSize(width: 0, height: -6)
        bubble.layer?.shadowRadius = 18
        bubble.layer?.shadowOpacity = 1.0
        bubble.alphaValue = 0 // Hidden initially until Doraemon reaches middle
        
        // Mini Bell / Face Icon on the Message Card (No emoji)
        let iconImageView = NSImageView(frame: NSRect(x: 14, y: (bubbleHeight - 34) / 2, width: 34, height: 34))
        iconImageView.image = loadBellIconImage()
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.wantsLayer = true
        iconImageView.layer?.cornerRadius = 8
        iconImageView.layer?.masksToBounds = true
        bubble.addSubview(iconImageView)
        
        // Header subtitle
        let headerLabel = NSTextField(labelWithString: "Doraemon Reminder")
        headerLabel.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        headerLabel.textColor = NSColor(red: 0.0, green: 0.59, blue: 0.84, alpha: 1.0)
        headerLabel.frame = NSRect(x: 56, y: bubbleHeight - 24, width: bubbleWidth - 70, height: 14)
        bubble.addSubview(headerLabel)
        
        // Main Message Label
        let msgLabel = NSTextField(labelWithString: message)
        msgLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        msgLabel.textColor = .white
        msgLabel.alignment = .left
        msgLabel.frame = NSRect(x: 56, y: 10, width: bubbleWidth - 70, height: bubbleHeight - 36)
        msgLabel.lineBreakMode = .byTruncatingTail
        msgLabel.maximumNumberOfLines = 2
        bubble.addSubview(msgLabel)
        
        contentView.addSubview(bubble)
        bubbleView = bubble
        messageLabel = msgLabel
        
        // Show fullscreen window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // ── Phase 1: Fly Doraemon from Left Edge to Middle Screen ──
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            imageView.animator().frame = NSRect(x: centerScreenX, y: flyY, width: doraemonSize, height: doraemonSize)
        }, completionHandler: { [weak self] in
            guard let self = self, !self.isDismissing else { return }
            
            // ── Phase 2: Take Letter Out & Display Message ──
            NSSound(named: "Glass")?.play()
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.bubbleView?.animator().alphaValue = 1.0
            })
            
            // Start gentle flying hover bobbing
            self.startHoverAnimation()
            
            // ── Phase 3: Keep open for 5 seconds ──
            self.autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
                self?.retractLetterAndFlyToRight()
            }
        })
        
        // Dismiss triggers (click or ESC)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.retractLetterAndFlyToRight()
            return event
        }
        
        escEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.retractLetterAndFlyToRight()
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
        hover.duration = 1.1
        hover.autoreverses = true
        hover.repeatCount = .infinity
        hover.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        imageView.layer?.add(hover, forKey: "hover")
    }
    
    // ── Phase 4 & 5: Put Letter Back & Fly to Extreme Right ──
    private func retractLetterAndFlyToRight() {
        guard !isDismissing else { return }
        isDismissing = true
        
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        
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
        let endExtremeRightX = screenWidth + 350 // Off the right edge of screen
        let currentY = imageView.frame.origin.y
        let width = imageView.frame.width
        let height = imageView.frame.height
        
        imageView.layer?.removeAnimation(forKey: "hover")
        
        // Step 4: Tucks letter back in
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.bubbleView?.animator().alphaValue = 0
            self.overlayWindow?.animator().alphaValue = 0.6
        }, completionHandler: { [weak self] in
            // Step 5: Doraemon accelerates and flies from middle to extreme right
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.9
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                imageView.animator().frame = NSRect(x: endExtremeRightX, y: currentY + 35, width: width, height: height)
                self?.overlayWindow?.animator().alphaValue = 0.0
            }, completionHandler: { [weak self] in
                self?.cleanup()
            })
        })
    }
    
    private func cleanup() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        doraemonImageView = nil
        bubbleView = nil
        messageLabel = nil
    }
    
    // ── Resource Loaders (No emoji fallbacks) ──
    private func loadDoraemonImage() -> NSImage? {
        if let img = NSImage(named: "doraemon") { return img }
        if let img = NSImage(named: "doraemon.webp") { return img }
        
        if let resourcePath = Bundle.main.resourcePath {
            let paths = [
                "\(resourcePath)/doraemon.webp",
                "\(resourcePath)/doraemon face.jpg",
                "\(resourcePath)/images/doraemon.webp"
            ]
            for path in paths {
                if let img = NSImage(contentsOfFile: path) { return img }
            }
        }
        return nil
    }
    
    private func loadBellIconImage() -> NSImage? {
        if let img = NSImage(named: "doraemon_bell") { return img }
        if let img = NSImage(named: "menuBarIcon") { return img }
        
        if let resourcePath = Bundle.main.resourcePath {
            let paths = [
                "\(resourcePath)/doraemon _bell.png",
                "\(resourcePath)/doraemon_bell.png",
                "\(resourcePath)/menuBarIcon@2x.png",
                "\(resourcePath)/menuBarIcon.png",
                "\(resourcePath)/doraemon face.jpg"
            ]
            for path in paths {
                if let img = NSImage(contentsOfFile: path) { return img }
            }
        }
        return nil
    }
}


