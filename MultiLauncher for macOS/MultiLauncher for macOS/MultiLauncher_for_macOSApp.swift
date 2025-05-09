
// MARK: - YourAppNameApp.swift
// Main application structure.
import SwiftUI

@main
struct MultiLauncher_for_macOSApp: App { // <<-- REPLACE YourAppNameApp with your actual app name
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { SettingsView().environmentObject(appDelegate.appSettings) }
    }
}
