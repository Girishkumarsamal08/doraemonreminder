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
        
        var yOffset: CGFloat = 420
        
        // ── Title ──
        let titleLabel = makeLabel("Doraemon Reminder", size: 16, bold: true)
        titleLabel.frame = NSRect(x: 20, y: yOffset, width: 280, height: 24)
        contentView.addSubview(titleLabel)
        yOffset -= 18
        
        let subtitleLabel = makeLabel("Set a time, Doraemon does the rest.", size: 11, bold: false)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.frame = NSRect(x: 20, y: yOffset, width: 280, height: 16)
        contentView.addSubview(subtitleLabel)
        yOffset -= 30
        
        // ── Separator ──
        addSeparator(at: yOffset, in: contentView)
        yOffset -= 16
        
        // ── Message ──
        let messageSectionLabel = makeSectionLabel("Message")
        messageSectionLabel.frame = NSRect(x: 20, y: yOffset, width: 280, height: 14)
        contentView.addSubview(messageSectionLabel)
        yOffset -= 28
        
        messageTextField = NSTextField(frame: NSRect(x: 20, y: yOffset, width: 280, height: 28))
        messageTextField.placeholderString = "Reminder"
        messageTextField.font = NSFont.systemFont(ofSize: 13)
        messageTextField.bezelStyle = .roundedBezel
        messageTextField.focusRingType = .exterior
        contentView.addSubview(messageTextField)
        yOffset -= 20
        
        // ── Separator ──
        addSeparator(at: yOffset, in: contentView)
        yOffset -= 16
        
        // ── Schedule ──
        let scheduleSectionLabel = makeSectionLabel("Schedule")
        scheduleSectionLabel.frame = NSRect(x: 20, y: yOffset, width: 280, height: 14)
        contentView.addSubview(scheduleSectionLabel)
        yOffset -= 34
        
        // At Time / Repeat Segmented Control
        scheduleSegment = NSSegmentedControl(labels: ["At Time", "Repeat"], trackingMode: .selectOne, target: self, action: #selector(scheduleTypeChanged))
        scheduleSegment.selectedSegment = 0
        scheduleSegment.frame = NSRect(x: 20, y: yOffset, width: 280, height: 28)
        contentView.addSubview(scheduleSegment)
        yOffset -= 40
        
        // Time picker row
        let timeRow = NSView(frame: NSRect(x: 20, y: yOffset, width: 280, height: 36))
        
        // Hour field
        hourField = NSTextField(frame: NSRect(x: 0, y: 0, width: 50, height: 36))
        hourField.stringValue = "08"
        hourField.font = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        hourField.alignment = .center
        hourField.bezelStyle = .roundedBezel
        timeRow.addSubview(hourField)
        
        let colonLabel = makeLabel(":", size: 20, bold: true)
        colonLabel.frame = NSRect(x: 55, y: 0, width: 15, height: 36)
        colonLabel.alignment = .center
        colonLabel.textColor = .tertiaryLabelColor
        timeRow.addSubview(colonLabel)
        
        // Minute field
        minuteField = NSTextField(frame: NSRect(x: 75, y: 0, width: 50, height: 36))
        minuteField.stringValue = "00"
        minuteField.font = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        minuteField.alignment = .center
        minuteField.bezelStyle = .roundedBezel
        timeRow.addSubview(minuteField)
        
        // AM/PM Segmented Control
        amPmSegment = NSSegmentedControl(labels: ["AM", "PM"], trackingMode: .selectOne, target: nil, action: nil)
        amPmSegment.selectedSegment = 0
        amPmSegment.frame = NSRect(x: 200, y: 2, width: 80, height: 32)
        amPmSegment.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        timeRow.addSubview(amPmSegment)
        
        contentView.addSubview(timeRow)
        yOffset -= 10
        
        // Repeat interval popup (hidden by default)
        repeatIntervalPopup = NSPopUpButton(frame: NSRect(x: 20, y: yOffset - 30, width: 280, height: 28))
        repeatIntervalPopup.addItems(withTitles: ["Every 15 minutes", "Every 30 minutes", "Every 1 hour", "Every 2 hours"])
        repeatIntervalPopup.isHidden = true
        contentView.addSubview(repeatIntervalPopup)
        
        yOffset -= 30
        
        // ── Upcoming Section ──
        upcomingDisclosure = NSButton(frame: NSRect(x: 14, y: yOffset, width: 290, height: 28))
        upcomingDisclosure.title = "  ⏳ Upcoming"
        upcomingDisclosure.bezelStyle = .inline
        upcomingDisclosure.setButtonType(.momentaryPushIn)
        upcomingDisclosure.isBordered = false
        upcomingDisclosure.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        upcomingDisclosure.target = self
        upcomingDisclosure.action = #selector(toggleUpcoming)
        upcomingDisclosure.alignment = .left
        contentView.addSubview(upcomingDisclosure)
        yOffset -= 6
        
        upcomingContainer = NSView(frame: NSRect(x: 20, y: yOffset - 30, width: 280, height: 30))
        upcomingContainer.isHidden = true
        
        upcomingLabel = makeLabel("No reminders scheduled", size: 11, bold: false)
        upcomingLabel.textColor = .secondaryLabelColor
        upcomingLabel.frame = NSRect(x: 0, y: 5, width: 280, height: 20)
        upcomingContainer.addSubview(upcomingLabel)
        contentView.addSubview(upcomingContainer)
        yOffset -= 10
        
        // ── Launch at Login ──
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(toggleLaunchAtLogin))
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: yOffset, width: 280, height: 20)
        launchAtLoginCheckbox.font = NSFont.systemFont(ofSize: 12)
        contentView.addSubview(launchAtLoginCheckbox)
        yOffset -= 20
        
        // ── Status ──
        let statusRow = NSView(frame: NSRect(x: 20, y: yOffset, width: 280, height: 16))
        
        statusDot = NSView(frame: NSRect(x: 120, y: 6, width: 6, height: 6))
        statusDot.wantsLayer = true
        statusDot.layer?.backgroundColor = NSColor.systemGray.cgColor
        statusDot.layer?.cornerRadius = 3
        statusRow.addSubview(statusDot)
        
        statusLabel = makeLabel("No reminder set", size: 10, bold: true)
        statusLabel.textColor = .tertiaryLabelColor
        statusLabel.frame = NSRect(x: 130, y: 0, width: 150, height: 16)
        statusRow.addSubview(statusLabel)
        
        contentView.addSubview(statusRow)
        yOffset -= 24
        
        // ── Buttons row ──
        let buttonWidth: CGFloat = 80
        let spacing: CGFloat = 10
        let totalWidth = buttonWidth * 3 + spacing * 2
        let startX = (320 - totalWidth) / 2
        
        // Test button
        testButton = NSButton(frame: NSRect(x: startX, y: yOffset, width: buttonWidth, height: 30))
        testButton.title = "Test"
        testButton.bezelStyle = .rounded
        testButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        testButton.target = self
        testButton.action = #selector(testReminder)
        contentView.addSubview(testButton)
        
        // Clear button
        clearButton = NSButton(frame: NSRect(x: startX + buttonWidth + spacing, y: yOffset, width: buttonWidth, height: 30))
        clearButton.title = "Clear All"
        clearButton.bezelStyle = .rounded
        clearButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        clearButton.target = self
        clearButton.action = #selector(clearReminders)
        contentView.addSubview(clearButton)
        
        // Set Reminder button (styled)
        setReminderButton = NSButton(frame: NSRect(x: startX + (buttonWidth + spacing) * 2, y: yOffset, width: buttonWidth, height: 30))
        setReminderButton.title = "Set Reminder"
        setReminderButton.bezelStyle = .rounded
        setReminderButton.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        setReminderButton.contentTintColor = .white
        setReminderButton.wantsLayer = true
        setReminderButton.layer?.backgroundColor = NSColor(red: 0, green: 0.59, blue: 0.84, alpha: 1).cgColor
        setReminderButton.layer?.cornerRadius = 6
        setReminderButton.isBordered = false
        setReminderButton.target = self
        setReminderButton.action = #selector(setReminder)
        contentView.addSubview(setReminderButton)
        yOffset -= 36
        
        // ── Quit ──
        quitButton = NSButton(frame: NSRect(x: 0, y: yOffset, width: 320, height: 24))
        quitButton.title = "Quit"
        quitButton.bezelStyle = .inline
        quitButton.isBordered = false
        quitButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        quitButton.contentTintColor = .secondaryLabelColor
        quitButton.target = self
        quitButton.action = #selector(quitApp)
        contentView.addSubview(quitButton)
    }
    
    // MARK: - Helper UI Builders
    private func makeLabel(_ text: String, size: CGFloat, bold: Bool) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? NSFont.systemFont(ofSize: size, weight: .bold) : NSFont.systemFont(ofSize: size)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        return label
    }
    
    private func makeSectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text.uppercased())
        label.font = NSFont.systemFont(ofSize: 9, weight: .bold)
        label.textColor = .tertiaryLabelColor
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        return label
    }
    
    private func addSeparator(at y: CGFloat, in parent: NSView) {
        let sep = NSBox(frame: NSRect(x: 20, y: y, width: 280, height: 1))
        sep.boxType = .separator
        parent.addSubview(sep)
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
