import Cocoa

class ReminderPopoverViewController: NSViewController {
    
    // MARK: - UI Elements
    private var messageTextField: NSTextField!
    private var hourField: NSTextField!
    private var minuteField: NSTextField!
    private var amPmSegment: NSSegmentedControl!
    private var scheduleSegment: NSSegmentedControl!
    private var repeatIntervalPopup: NSPopUpButton!
    private var setReminderButton: NSButton!
    private var testButton: NSButton!
    private var clearButton: NSButton!
    private var quitButton: NSButton!
    private var launchAtLoginCheckbox: NSButton!
    private var statusLabel: NSTextField!
    private var statusDot: NSView!
    private var upcomingDisclosure: NSButton!
    private var upcomingContainer: NSView!
    private var upcomingLabel: NSTextField!
    
    // MARK: - State
    private var reminderTimer: Timer?
    private var repeatTimer: Timer?
    private var isRepeatMode = false
    private var upcomingExpanded = false
    private var scheduledTime: Date?
    private var scheduledMessage: String?
    
    // MARK: - View Lifecycle
    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 460))
        container.wantsLayer = true
        self.view = container
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        let contentView = self.view
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1.0).cgColor
        
        var yOffset: CGFloat = 415
        
        // ── Header Title ──
        let titleRow = NSView(frame: NSRect(x: 20, y: yOffset, width: 280, height: 28))
        let titleLabel = makeLabel("Doraemon Reminder", size: 16, bold: true, color: .white)
        titleLabel.frame = NSRect(x: 0, y: 2, width: 250, height: 24)
        titleRow.addSubview(titleLabel)
        contentView.addSubview(titleRow)
        yOffset -= 20
        
        // Subtitle divider line
        let divider1 = makeDivider(y: yOffset)
        contentView.addSubview(divider1)
        yOffset -= 18
        
        // ── Message Section ──
        let msgHeader = makeSectionHeader("💬 Message")
        msgHeader.frame = NSRect(x: 20, y: yOffset, width: 280, height: 16)
        contentView.addSubview(msgHeader)
        yOffset -= 32
        
        messageTextField = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 280, height: 32))
        messageTextField.placeholderString = "Reminder"
        messageTextField.stringValue = ""
        messageTextField.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        messageTextField.textColor = .white
        messageTextField.wantsLayer = true
        messageTextField.layer?.backgroundColor = NSColor(red: 0.13, green: 0.15, blue: 0.20, alpha: 1.0).cgColor
        messageTextField.layer?.borderColor = NSColor(red: 0.0, green: 0.59, blue: 0.84, alpha: 0.8).cgColor
        messageTextField.layer?.borderWidth = 1.5
        messageTextField.layer?.cornerRadius = 8
        messageTextField.isBordered = false
        messageTextField.focusRingType = .none
        contentView.addSubview(messageTextField)
        yOffset -= 28
        
        // ── Schedule Section ──
        let scheduleHeader = makeSectionHeader("🕒 Schedule")
        scheduleHeader.frame = NSRect(x: 20, y: yOffset, width: 280, height: 16)
        contentView.addSubview(scheduleHeader)
        yOffset -= 38
        
        // At Time / Repeat Toggle Switcher
        scheduleSegment = NSSegmentedControl(labels: ["At Time", "Repeat"], trackingMode: .selectOne, target: self, action: #selector(scheduleTypeChanged))
        scheduleSegment.selectedSegment = 0
        scheduleSegment.frame = NSRect(x: 60, y: yOffset, width: 200, height: 28)
        scheduleSegment.wantsLayer = true
        scheduleSegment.segmentStyle = .capsule
        contentView.addSubview(scheduleSegment)
        yOffset -= 48
        
        // ── Time Input Card ──
        let timeCard = NSView(frame: NSRect(x: 20, y: yOffset, width: 280, height: 44))
        timeCard.wantsLayer = true
        timeCard.layer?.backgroundColor = NSColor(red: 0.13, green: 0.15, blue: 0.20, alpha: 0.8).cgColor
        timeCard.layer?.cornerRadius = 10
        timeCard.layer?.borderColor = NSColor(white: 1.0, alpha: 0.06).cgColor
        timeCard.layer?.borderWidth = 1
        
        // Hour Box
        hourField = NSTextField(frame: NSRect(x: 12, y: 6, width: 44, height: 32))
        hourField.stringValue = "08"
        hourField.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        hourField.textColor = .white
        hourField.alignment = .center
        hourField.isBordered = false
        hourField.focusRingType = .none
        hourField.wantsLayer = true
        hourField.layer?.backgroundColor = NSColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1.0).cgColor
        hourField.layer?.cornerRadius = 6
        timeCard.addSubview(hourField)
        
        let colon = makeLabel(":", size: 18, bold: true, color: NSColor(white: 1.0, alpha: 0.5))
        colon.frame = NSRect(x: 58, y: 8, width: 10, height: 28)
        colon.alignment = .center
        timeCard.addSubview(colon)
        
        // Minute Box
        minuteField = NSTextField(frame: NSRect(x: 70, y: 6, width: 44, height: 32))
        minuteField.stringValue = "00"
        minuteField.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        minuteField.textColor = .white
        minuteField.alignment = .center
        minuteField.isBordered = false
        minuteField.focusRingType = .none
        minuteField.wantsLayer = true
        minuteField.layer?.backgroundColor = NSColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1.0).cgColor
        minuteField.layer?.cornerRadius = 6
        timeCard.addSubview(minuteField)
        
        // AM / PM Toggle
        amPmSegment = NSSegmentedControl(labels: ["AM", "PM"], trackingMode: .selectOne, target: nil, action: nil)
        amPmSegment.selectedSegment = 0
        amPmSegment.frame = NSRect(x: 180, y: 8, width: 88, height: 28)
        amPmSegment.segmentStyle = .capsule
        timeCard.addSubview(amPmSegment)
        
        contentView.addSubview(timeCard)
        yOffset -= 8
        
        // Repeat interval popup (hidden until Repeat selected)
        repeatIntervalPopup = NSPopUpButton(frame: NSRect(x: 20, y: yOffset - 32, width: 280, height: 28))
        repeatIntervalPopup.addItems(withTitles: ["Every 15 minutes", "Every 30 minutes", "Every 1 hour", "Every 2 hours"])
        repeatIntervalPopup.isHidden = true
        contentView.addSubview(repeatIntervalPopup)
        yOffset -= 32
        
        // ── Upcoming Section Divider ──
        let divider2 = makeDivider(y: yOffset)
        contentView.addSubview(divider2)
        yOffset -= 24
        
        // Upcoming disclosure toggle
        upcomingDisclosure = NSButton(frame: NSRect(x: 20, y: yOffset, width: 280, height: 22))
        upcomingDisclosure.title = "🔄 Upcoming"
        upcomingDisclosure.bezelStyle = .inline
        upcomingDisclosure.isBordered = false
        upcomingDisclosure.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        upcomingDisclosure.contentTintColor = .white
        upcomingDisclosure.target = self
        upcomingDisclosure.action = #selector(toggleUpcoming)
        upcomingDisclosure.alignment = .left
        contentView.addSubview(upcomingDisclosure)
        yOffset -= 4
        
        upcomingContainer = NSView(frame: NSRect(x: 20, y: yOffset - 26, width: 280, height: 26))
        upcomingContainer.isHidden = true
        
        upcomingLabel = makeLabel("No reminders scheduled", size: 11, bold: false, color: NSColor(white: 1.0, alpha: 0.6))
        upcomingLabel.frame = NSRect(x: 4, y: 3, width: 272, height: 20)
        upcomingContainer.addSubview(upcomingLabel)
        contentView.addSubview(upcomingContainer)
        yOffset -= 30
        
        // ── Launch at Login ──
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(toggleLaunchAtLogin))
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: yOffset, width: 280, height: 20)
        launchAtLoginCheckbox.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        launchAtLoginCheckbox.contentTintColor = NSColor(white: 1.0, alpha: 0.85)
        contentView.addSubview(launchAtLoginCheckbox)
        yOffset -= 40
        
        // ── Bottom Action Buttons ──
        // Test Button
        testButton = NSButton(frame: NSRect(x: 20, y: yOffset, width: 64, height: 32))
        testButton.title = "Test"
        testButton.bezelStyle = .rounded
        testButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        testButton.target = self
        testButton.action = #selector(testReminder)
        contentView.addSubview(testButton)
        
        // Clear All Button
        clearButton = NSButton(frame: NSRect(x: 90, y: yOffset, width: 76, height: 32))
        clearButton.title = "Clear All"
        clearButton.bezelStyle = .rounded
        clearButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        clearButton.target = self
        clearButton.action = #selector(clearReminders)
        contentView.addSubview(clearButton)
        
        // Set Reminder (Red button matching screenshot)
        setReminderButton = NSButton(frame: NSRect(x: 172, y: yOffset, width: 128, height: 32))
        setReminderButton.title = "Set Reminder"
        setReminderButton.bezelStyle = .regularSquare
        setReminderButton.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        setReminderButton.contentTintColor = .white
        setReminderButton.wantsLayer = true
        setReminderButton.layer?.backgroundColor = NSColor(red: 0.88, green: 0.11, blue: 0.15, alpha: 1.0).cgColor
        setReminderButton.layer?.cornerRadius = 8
        setReminderButton.isBordered = false
        setReminderButton.target = self
        setReminderButton.action = #selector(setReminder)
        contentView.addSubview(setReminderButton)
        yOffset -= 32
        
        // ── Quit Button ──
        quitButton = NSButton(frame: NSRect(x: 0, y: yOffset, width: 320, height: 22))
        quitButton.title = "Quit"
        quitButton.bezelStyle = .inline
        quitButton.isBordered = false
        quitButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        quitButton.contentTintColor = NSColor(white: 1.0, alpha: 0.45)
        quitButton.target = self
        quitButton.action = #selector(quitApp)
        contentView.addSubview(quitButton)
    }
    
    // MARK: - Helper UI Builders
    private func makeLabel(_ text: String, size: CGFloat, bold: Bool, color: NSColor = .white) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? NSFont.systemFont(ofSize: size, weight: .bold) : NSFont.systemFont(ofSize: size)
        label.textColor = color
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        return label
    }
    
    private func makeSectionHeader(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = NSColor(white: 1.0, alpha: 0.7)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        return label
    }
    
    private func makeDivider(y: CGFloat) -> NSView {
        let line = NSView(frame: NSRect(x: 20, y: y, width: 280, height: 1))
        line.wantsLayer = true
        line.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.08).cgColor
        return line
    }
    
    // MARK: - Actions
    @objc private func scheduleTypeChanged() {
        isRepeatMode = scheduleSegment.selectedSegment == 1
        repeatIntervalPopup.isHidden = !isRepeatMode
    }
    
    @objc private func toggleUpcoming() {
        upcomingExpanded.toggle()
        upcomingContainer.isHidden = !upcomingExpanded
        upcomingDisclosure.title = upcomingExpanded ? "  ⏳ Upcoming  ▼" : "  ⏳ Upcoming  ▶"
    }
    
    @objc private func toggleLaunchAtLogin() {
        // Toggle launch at login via SMLoginItemSetEnabled or LaunchAgent
        // For simplicity, we store the preference
        let enabled = launchAtLoginCheckbox.state == .on
        UserDefaults.standard.set(enabled, forKey: "LaunchAtLogin")
    }
    
    @objc private func setReminder() {
        let message = messageTextField.stringValue.isEmpty ? "Reminder" : messageTextField.stringValue
        
        if isRepeatMode {
            // Repeat mode
            let intervals: [TimeInterval] = [900, 1800, 3600, 7200] // 15m, 30m, 1h, 2h
            let interval = intervals[repeatIntervalPopup.indexOfSelectedItem]
            
            repeatTimer?.invalidate()
            repeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.showDoraemonDrop(message: message)
            }
            
            updateStatus(active: true, text: "Repeating every \(repeatIntervalPopup.titleOfSelectedItem ?? "")")
            updateUpcoming(text: "🔁 \(message) — \(repeatIntervalPopup.titleOfSelectedItem ?? "")")
        } else {
            // At Time mode
            guard let hour = Int(hourField.stringValue),
                  let minute = Int(minuteField.stringValue),
                  hour >= 1, hour <= 12,
                  minute >= 0, minute <= 59 else {
                statusLabel.stringValue = "Invalid time"
                return
            }
            
            var adjustedHour = hour
            let isPM = amPmSegment.selectedSegment == 1
            
            if isPM && hour != 12 {
                adjustedHour += 12
            } else if !isPM && hour == 12 {
                adjustedHour = 0
            }
            
            // Calculate target date
            let calendar = Calendar.current
            let now = Date()
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = adjustedHour
            components.minute = minute
            components.second = 0
            
            guard var targetDate = calendar.date(from: components) else { return }
            
            // If the time has already passed today, schedule for tomorrow
            if targetDate <= now {
                targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
            }
            
            let timeInterval = targetDate.timeIntervalSince(now)
            scheduledTime = targetDate
            scheduledMessage = message
            
            reminderTimer?.invalidate()
            reminderTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.showDoraemonDrop(message: message)
                self?.updateStatus(active: false, text: "No reminder set")
                self?.updateUpcoming(text: "No reminders scheduled")
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let timeString = formatter.string(from: targetDate)
            
            updateStatus(active: true, text: "Set for \(timeString)")
            updateUpcoming(text: "⏰ \(message) — \(timeString)")
        }
    }
    
    @objc private func testReminder() {
        let message = messageTextField.stringValue.isEmpty ? "This is a test reminder!" : messageTextField.stringValue
        showDoraemonDrop(message: message)
    }
    
    @objc private func clearReminders() {
        reminderTimer?.invalidate()
        reminderTimer = nil
        repeatTimer?.invalidate()
        repeatTimer = nil
        scheduledTime = nil
        scheduledMessage = nil
        updateStatus(active: false, text: "No reminder set")
        updateUpcoming(text: "No reminders scheduled")
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Status Updates
    private func updateStatus(active: Bool, text: String) {
        statusLabel.stringValue = text
        statusDot.layer?.backgroundColor = active ? NSColor.systemGreen.cgColor : NSColor.systemGray.cgColor
    }
    
    private func updateUpcoming(text: String) {
        upcomingLabel.stringValue = text
    }
    
    // MARK: - Doraemon Drop Animation
    private func showDoraemonDrop(message: String) {
        DispatchQueue.main.async {
            let dropController = DropAnimationWindowController(message: message)
            dropController.showDrop()
        }
    }
}
