<div align="center">

  <img src="images/doraemon.webp" alt="Doraemon Reminder" width="160" />

  # Doraemon Reminder 🔔

  **Magical reminders from your favorite robot cat — right on your macOS menu bar!**

  [![macOS](https://img.shields.io/badge/macOS-12.0%2B-blue?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/Girishkumarsamal08/doraemonreminder)
  [![License](https://img.shields.io/badge/License-Free-brightgreen?style=for-the-badge)](https://github.com/Girishkumarsamal08/doraemonreminder)
  [![Live Website](https://img.shields.io/badge/Website-doraemonreminder.vercel.app-0096D6?style=for-the-badge&logo=vercel&logoColor=white)](https://doraemonreminder.vercel.app)
  [![Download DMG](https://img.shields.io/badge/Download-DoraemonReminder.dmg-E60012?style=for-the-badge&logo=apple&logoColor=white)](https://doraemonreminder.vercel.app/DoraemonReminder.dmg)

</div>

---

## 🌟 Overview

**Doraemon Reminder** is a lightweight, distraction-free macOS menu bar application inspired by Doraemon. Instead of annoying default system alerts, Doraemon flies onto your screen with a smooth animation and presents your scheduled reminder inside a cartoon speech bubble!

🌐 **Live Website**: [doraemonreminder.vercel.app](https://doraemonreminder.vercel.app)

---

## ✨ Features

- 📍 **Menu Bar Resident**: Sits cleanly in your macOS menu bar with no Dock clutter (`LSUIElement = true`).
- ⏰ **Flexible Scheduling**:
  - **At Time**: Set a specific hour & minute (AM/PM) for precise triggers.
  - **Repeat**: Schedule recurring periodic reminders (15m, 30m, 1h, 2h).
- 🎬 **Animated Screen Drop**: Doraemon flies down from the top of your screen with subtle bobbing physics.
- 💬 **Speech Bubble Message**: Custom reminder message displayed prominently alongside Doraemon.
- ⚡ **Instant Dismissal**: Hit `ESC` or click anywhere on the screen to dismiss. Auto-dismisses after 15 seconds.
- 🧪 **Test Now & Clear All**: Instantly preview the animation or clear all active timers in one click.
- 🚀 **Launch at Login**: Easily toggle start-on-boot preference.
- 💯 **100% Free Forever**: No trackers, no telemetry, no paid tier.

---

## 📥 Installation

1. **Download the DMG**:
   - Download [`DoraemonReminder.dmg`](https://doraemonreminder.vercel.app/DoraemonReminder.dmg) directly or from the [Releases](https://github.com/Girishkumarsamal08/doraemonreminder/releases).
2. **Mount and Install**:
   - Open `DoraemonReminder.dmg`.
   - Drag **DoraemonReminder.app** into your **Applications** folder.
3. **Launch**:
   - Open **DoraemonReminder** from Launchpad or Applications.
   - Look for the bell icon in your macOS menu bar (top-right).

> [!TIP]
> ### 🛡️ macOS Security Warning (Gatekeeper)
> Since the app is built without an Apple Developer Paid Certificate:
> 1. If macOS says *"DoraemonReminder cannot be opened because the developer cannot be verified"*:
> 2. Open **System Settings** > **Privacy & Security**.
> 3. Scroll down to the **Security** section and click **Open Anyway**.

---

## 🎮 How to Use & Controls

| Action | Control |
|---|---|
| **Open Settings** | Click the menu bar icon in the top right |
| **Set Reminder** | Type message → pick time → click **Set Reminder** |
| **Test Animation** | Click the **Test** button in the popover |
| **Dismiss Doraemon** | Press <kbd>ESC</kbd> or click anywhere on the screen |
| **Clear Timers** | Click **Clear All** |
| **Quit App** | Click **Quit** at the bottom of the popover |

---

## 🏗️ Project Structure

```
doraemonreminder/
├── index.html                       # Landing page (deployed to Vercel root)
├── manual.html                      # Manual & FAQs page
├── vercel.json                      # Vercel deployment configuration
├── DoraemonReminder.dmg             # Pre-built macOS disk image installer
├── images/                          # Web and media assets
│   ├── doraemon.webp
│   ├── doraemon face.jpg
│   ├── doraemon name.png
│   └── done.mp4
└── DoraemonReminder/                # Native Swift macOS App Source
    ├── DoraemonReminder.xcodeproj   # Xcode Project file
    └── DoraemonReminder/
        ├── AppDelegate.swift                  # Status bar item & Popover controller
        ├── ReminderPopoverViewController.swift# Main popup UI & timer logic
        ├── DropAnimationWindowController.swift# Fullscreen animation & speech bubble
        ├── Info.plist                         # App metadata & LSUIElement flag
        └── Assets.xcassets/                   # App icons & image sets
```

---

## 🛠️ Building from Source

### Prerequisites
- macOS 12.0 (Monterey) or later
- Swift 5.0+ / Xcode Command Line Tools

### 1. Build the Binary
```bash
# Clone the repository
git clone https://github.com/Girishkumarsamal08/doraemonreminder.git
cd doraemonreminder

# Create app bundle structure
mkdir -p build/DoraemonReminder.app/Contents/MacOS build/DoraemonReminder.app/Contents/Resources

# Compile with swiftc
swiftc -target arm64-apple-macosx12.0 -O -framework Cocoa -framework QuartzCore \
  DoraemonReminder/DoraemonReminder/AppDelegate.swift \
  DoraemonReminder/DoraemonReminder/ReminderPopoverViewController.swift \
  DoraemonReminder/DoraemonReminder/DropAnimationWindowController.swift \
  -o build/DoraemonReminder.app/Contents/MacOS/DoraemonReminder

# Copy metadata and resources
cp DoraemonReminder/DoraemonReminder/Info.plist build/DoraemonReminder.app/Contents/Info.plist
cp doraemon.webp build/DoraemonReminder.app/Contents/Resources/doraemon.webp
echo '<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundlePackageType</key><string>APPL</string></dict></plist>' > build/DoraemonReminder.app/Contents/PkgInfo
```

### 2. Package into `.dmg`
```bash
# Create staging folder with Applications shortcut
mkdir -p /tmp/dmg_staging
cp -R build/DoraemonReminder.app /tmp/dmg_staging/
ln -s /Applications /tmp/dmg_staging/Applications

# Generate DMG
hdiutil create -volname "Doraemon Reminder" -srcfolder /tmp/dmg_staging -ov -format UDZO DoraemonReminder.dmg
rm -rf /tmp/dmg_staging
```

---

## 👨‍💻 Author

Created with 💙 by **Girish Kumar Samal**
- Instagram: [@just._.mickey___](https://www.instagram.com/just._.mickey___/)
- GitHub: [@Girishkumarsamal08](https://github.com/Girishkumarsamal08)
- Email: [girishkumarsamal08@gmail.com](mailto:girishkumarsamal08@gmail.com)

---

## ⚖️ License

This project is licensed for personal and educational use. Doraemon is a trademark of Fujiko Pro / Shin-Ei Animation.
