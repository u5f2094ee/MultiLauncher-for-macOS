# MultiLauncher for macOS

![Screenshot](https://github.com/user-attachments/assets/55f90ba1-7748-4070-bbee-6295da28f734)


---

# Overview

**MultiLauncher for macOS** is a sleek, minimalist application launcher designed for quick and streamlined access to your favorite apps. Built with SwiftUI, it provides a customizable, blurred, and transparent pad that appears on demand, keeping your desktop uncluttered.

Inspired by the desire for a more focused alternative to traditional launchers, MultiLauncher allows you to create a personalized space for the apps you use most, accessible via a global hotkey or a discreet menu bar icon.

---

# Features

### Core Functionality
- **Minimalist Launch Pad**: A blurred, transparent, and rounded pad that displays user-added application icons.
- **Quick Launch**: Click an app icon to instantly launch the corresponding application.
- **Background Operation**: Runs discreetly in the background without a Dock icon.
- **On-Demand Visibility**:
    - Activate the launch pad using a configurable global hotkey.
    - Control visibility via a menu bar icon.
- **Auto-Dismiss**: The launch pad automatically hides after launching an app or clicking outside its boundary.
- **Idle Auto-Hide**: Configurable timer to automatically hide the launch pad after a period of inactivity.

### Customization & Management (via Settings)
- **App Management**:
    - Add applications from your /Application.
    - Remove applications from the launcher Preferences.
    - Rearrange the order of applications on the pad.
- **Appearance Customization**:
    - Adjust the number of app icons per row.
    - Set the size of the app icons.
    - Configure the spacing between app icons.
- **Shortcut Configuration**:
    - Modify the global hotkey (modifiers and key) to activate the launch pad.
    - *Note: UI for key input is character-based; a full key recorder is a future enhancement.*

### User Interface
- **Menubar Icon**: Provides quick access to show/hide the launcher, open preferences, view 'About' information, and quit the application.
- **Dynamic Sizing**: The launch pad attempts to resize based on the number of apps and configured layout.
- **Centered Display**: The launch pad always appears centered on the screen.

---

# How to Run

### From Xcode:
1. Open the project in **Xcode 15** or later.
2. Ensure your Mac is running **macOS 14.0 or newer** (or the minimum version specified in the project settings).
3. Build and run the app.
4. Configure your desired apps and settings via the menu bar icon > Preferences.
5. Use the global hotkey or the menu bar icon to show/hide the launcher.

### Direct Launch (e.g., from a `.app` bundle):
1. If you have compiled the `.app` bundle or downloaded a pre-built version.
2. Double-click the `MultiLauncher for macOS.app` file.
3. **Accessibility Permissions**: For the global hotkey to function correctly, you **must** grant Accessibility permissions to MultiLauncher:
    - Go to **System Settings → Privacy & Security → Accessibility**.
    - Click the **+** button, navigate to MultiLauncher, and add it to the list.
    - Ensure the toggle next to MultiLauncher is **enabled**.
    - You might need to restart MultiLauncher after granting permissions.
4. If macOS blocks the app due to unidentified developer (if not notarized):
    - Go to **System Settings → Privacy & Security**.
    - Scroll down to the "Security" section.
    - You should see a message about "MultiLauncher for macOS" being blocked. Click **“Open Anyway”**.

---

# Requirements

- macOS 14.0 or later (adjust if your project targets an earlier version).
- Xcode 15 or later (for building from source).

---

# Acknowledgements

This application was developed with the assistance of Gemini, a large language model from Google.
Your icon `icon_1024x1024.png` (assumed to be named `AppIconCustom` in Assets.xcassets) is used for the 'About' panel.
