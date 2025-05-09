
// MARK: - AppDelegate.swift
// Handles custom window, menubar icon, global hotkey, and app lifecycle.
import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var settingsWindow: NSWindow?
    var aboutWindow: NSWindow?
    var statusItem: NSStatusItem?
    let appSettings = AppSettings()
    var hotKeyMonitor: Any?
    var showLauncherMenuItem: NSMenuItem!
    private var settingsCancellable: AnyCancellable?
    private var idleTimerCancellable: AnyCancellable?
    private var idleTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView(
            hideWindowAction: { [weak self] in self?.hideWindow() },
            resetIdleTimerAction: { [weak self] in self?.resetIdleTimer() }
        ).environmentObject(appSettings)
        
        window = NSWindow(
            contentRect:NSRect(x:0,y:0,width:600,height:500), styleMask:[.borderless],
            backing:.buffered, defer:false)
        window.isOpaque = false; window.backgroundColor = .clear
        window.hasShadow = false;
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        window.contentView = NSHostingView(rootView: contentView)
        window.acceptsMouseMovedEvents = true

        setupStatusItem()
        setupHotKeySubscription()
        setupIdleTimerSubscription()
        
        // Show launcher window on startup
        showWindow()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem?.button {
            btn.image = NSImage(systemSymbolName: "square.grid.3x3.fill", accessibilityDescription: "squaregrid")
        }
        let menu = NSMenu()
        showLauncherMenuItem = NSMenuItem(title: "Show Launcher", action: #selector(toggleLauncherVisibilityAction), keyEquivalent: "")
        menu.addItem(showLauncherMenuItem)
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferencesAction), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "About Launcher", action: #selector(openAboutPanelAction), keyEquivalent: ""))
        menu.addItem(.separator()); menu.addItem(NSMenuItem(title: "Quit Launcher", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        updateShowLauncherMenuItemTitle()
    }
    
    @objc func openAboutPanelAction() {
        if aboutWindow == nil || !(aboutWindow?.isVisible ?? false) {
            let appIcon: NSImage = NSImage(named: "AppIconCustom") ?? NSApp.applicationIconImage ?? NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: "App Icon")!

            let aboutView = VStack(spacing: 10) {
                Image(nsImage: appIcon)
                    .resizable().frame(width: 64, height: 64).cornerRadius(12)
                Text("MultiLauncher for macOS").font(.title2)
                Text("Version 1.0 (20250509)")
                    .font(.callout).foregroundColor(.secondary)
                Text("Developed by Zhang Zheng with Gemini 2.5 Pro.")
                    .font(.caption).padding(.top, 5)
                Link("GitHub: u5f2094ee/MultiLauncher-for-macOS", destination: URL(string: "https://github.com/u5f2094ee/MultiLauncher-for-macOS")!)
                    .font(.caption)
                Text("Special thanks to Gemini 2.5 Pro, GPT-o3, and GPT-o4-mini-high for their invaluable support and contributions to this project.")
                    .font(.footnote).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
            }.padding(30).frame(width: 350, height: 320)

            aboutWindow = NSWindow(
                contentRect: NSRect(x:0,y:0,width:350,height:320),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false
            )
            aboutWindow?.center()
            aboutWindow?.title = "About \(Bundle.main.appName ?? "MultiLauncher")"
            aboutWindow?.isReleasedWhenClosed = false
            aboutWindow?.contentView = NSHostingView(rootView: aboutView)
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func setupHotKeySubscription() {
        registerCurrentHotKey()
        settingsCancellable = appSettings.hotkeySettingsChanged
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] in
                print("AppDelegate: Hotkey settings changed signal received, re-registering hotkey.")
                self?.registerCurrentHotKey()
            }
    }

    func setupIdleTimerSubscription() {
        idleTimerCancellable = appSettings.idleTimerSettingsChanged
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] in
                print("AppDelegate: Idle timer settings changed signal received.")
                if self?.window.isVisible ?? false { self?.startIdleTimer() }
            }
    }
    
    func registerCurrentHotKey() {
        if let existing = hotKeyMonitor {
            NSEvent.removeMonitor(existing)
            hotKeyMonitor = nil
            print("AppDelegate: Removed existing hotkey monitor.")
        }
        
        let effectiveKeyCode = appSettings.shortcutKeyCode
        let modFlags = appSettings.shortcutModifierFlags
        
        print("AppDelegate: Attempting to register hotkey. Effective Code: \(effectiveKeyCode), Effective Flags: \(modFlags), Display: \(appSettings.activationHotkeyDisplayString)")

        guard !modFlags.isEmpty || effectiveKeyCode != 0 else {
            print("AppDelegate: Hotkey setup SKIPPED: Invalid configuration (no modifiers and key code is 0, or no key character set)."); return
        }

        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let latestKeyCode = self.appSettings.shortcutKeyCode
            let latestModFlags = self.appSettings.shortcutModifierFlags
            
            let eventMods = event.modifierFlags.intersection([.command, .option, .shift, .control])

            // print("Global KeyDown: Event Code \(event.keyCode), Event Mods \(eventMods) | Target: Code \(latestKeyCode), Mods \(latestModFlags)")

            if event.keyCode == latestKeyCode && eventMods == latestModFlags {
                print("AppDelegate: Hotkey ACTIVATED! Code:\(event.keyCode), Mods:\(eventMods)")
                self.toggleLauncherVisibility()
            }
        }
        if hotKeyMonitor != nil {
            print("AppDelegate: Hotkey successfully registered. Code:\(effectiveKeyCode), Flags:\(modFlags).")
        } else {
            print("AppDelegate: FAILED to register hotkey. Code:\(effectiveKeyCode), Flags:\(modFlags). CHECK ACCESSIBILITY PERMISSIONS and ensure the shortcut is not globally used by another app.")
        }
    }

    @objc func openPreferencesAction() {
        if settingsWindow == nil || !(settingsWindow?.isVisible ?? false) {
            let sView = SettingsView().environmentObject(appSettings)
            settingsWindow = NSWindow(
                contentRect:NSRect(x:0,y:0,width:600,height:900),
                styleMask:[.titled,.closable,.miniaturizable,.resizable],
                backing:.buffered, defer:false)
            settingsWindow?.center(); settingsWindow?.title = "Launcher Preferences"
            settingsWindow?.isReleasedWhenClosed = false; settingsWindow?.contentView = NSHostingView(rootView: sView)
        }
        settingsWindow?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }

    @objc func toggleLauncherVisibilityAction() { toggleLauncherVisibility() }
    func toggleLauncherVisibility() { if window.isVisible { hideWindow() } else { showWindow() } }
    
    func showWindow() {
        guard let w = window else {return}
        w.center()
        var currentFrame = w.frame
        let nudgeAmountY: CGFloat = 100.0
        currentFrame.origin.y -= nudgeAmountY
        
        if let screen = w.screen ?? NSScreen.main {
            let screenVisibleFrame = screen.visibleFrame
            if currentFrame.minY < screenVisibleFrame.minY {
                 currentFrame.origin.y = screenVisibleFrame.minY
            }
            if currentFrame.maxY > screenVisibleFrame.maxY {
                currentFrame.origin.y = screenVisibleFrame.maxY - currentFrame.height
            }
        }
        w.setFrameOrigin(currentFrame.origin)

        w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true)
        updateShowLauncherMenuItemTitle()
        startIdleTimer()
    }
    func hideWindow() {
        guard let w = window else {return}
        w.orderOut(nil)
        updateShowLauncherMenuItemTitle()
        invalidateIdleTimer()
    }
    
    func updateShowLauncherMenuItemTitle() { guard let item = showLauncherMenuItem else {return}; item.title = window.isVisible ? "Hide Launcher" : "Show Launcher" }

    func startIdleTimer() {
        invalidateIdleTimer()
        let delay = appSettings.idleHideDelaySeconds
        guard delay > 0 else { return }
        print("Starting idle timer for \(delay) seconds.")
        idleTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            print("Idle timer fired. Hiding window.")
            self?.hideWindow()
        }
    }

    func invalidateIdleTimer() { idleTimer?.invalidate(); idleTimer = nil }
    func resetIdleTimer() { if window.isVisible && appSettings.idleHideDelaySeconds > 0 { startIdleTimer() } }

    func applicationWillTerminate(_ notification: Notification) {
        if let mon = hotKeyMonitor { NSEvent.removeMonitor(mon); hotKeyMonitor = nil }
        invalidateIdleTimer()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { if !flag { showWindow() }; return true }
}
