# 🤖 Doraemon Reminder

A free macOS menu bar reminder app featuring Doraemon! Set reminders and let Doraemon fly onto your screen to deliver them.

![Doraemon](doraemon.webp)

## ✨ Features

- **Menu Bar App** — Lives in your Mac's menu bar, no dock clutter
- **Custom Reminders** — Set messages with exact time scheduling
- **At Time / Repeat** — Schedule one-time or recurring reminders
- **Doraemon Animation** — Doraemon flies down from the top of your screen with a speech bubble
- **Quick Dismiss** — Press ESC or click anywhere to close
- **Launch at Login** — Optional auto-start
- **100% Free** — No ads, no costs, forever

## 📥 Download

Download the latest `.dmg` from the [releases](DoraemonReminder.dmg) or from the website.

## 🌐 Website

The landing page is in the `website/` folder. Deploy to Vercel or any static hosting.

## 🛠 Building from Source

### Requirements
- macOS 12+
- Swift 5.0+

### Build
```bash
mkdir -p build/DoraemonReminder.app/Contents/MacOS build/DoraemonReminder.app/Contents/Resources
swiftc -target arm64-apple-macosx12.0 -O -framework Cocoa -framework QuartzCore \
  DoraemonReminder/DoraemonReminder/AppDelegate.swift \
  DoraemonReminder/DoraemonReminder/ReminderPopoverViewController.swift \
  DoraemonReminder/DoraemonReminder/DropAnimationWindowController.swift \
  -o build/DoraemonReminder.app/Contents/MacOS/DoraemonReminder
cp DoraemonReminder/DoraemonReminder/Info.plist build/DoraemonReminder.app/Contents/Info.plist
cp doraemon.webp build/DoraemonReminder.app/Contents/Resources/doraemon.webp
```

### Create DMG
```bash
hdiutil create -volname "DoraemonReminder" -srcfolder build/DoraemonReminder.app -ov -format UDZO DoraemonReminder.dmg
```

## 📁 Project Structure

```
doraemon_reminder/
├── website/                    # Landing page
│   ├── index.html             # Homepage
│   ├── manual.html            # Manual & FAQs
│   ├── DoraemonReminder.dmg   # Download
│   └── images/
│       ├── doraemon.webp      # Doraemon mascot
│       └── done.mp4           # Installation video
├── DoraemonReminder/          # Swift macOS app source
│   ├── DoraemonReminder.xcodeproj/
│   └── DoraemonReminder/
│       ├── AppDelegate.swift
│       ├── ReminderPopoverViewController.swift
│       ├── DropAnimationWindowController.swift
│       ├── Assets.xcassets/
│       └── Info.plist
├── DoraemonReminder.dmg       # Pre-built app
├── doraemon.webp
└── done.mp4
```

## 📄 License

Free to use. Made with 💙 by Girish Kumar Samal.
