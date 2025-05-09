
// MARK: - ContentView.swift
// Purpose: Hosts the launcher pad within the main window.

import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    let hideWindowAction: () -> Void
    let resetIdleTimerAction: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .edgesIgnoringSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    print("ContentView: Background tapped, hiding window.")
                    hideWindowAction()
                }
                .onHover { hovering in
                    if hovering { resetIdleTimerAction() }
                }

            LauncherPadView(onLaunchApp: { appItem in
                launchApp(appItem); hideWindowAction()
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                print("ContentView: LauncherPad tapped, resetting idle timer.")
                resetIdleTimerAction()
            }
            .onHover { hovering in
                 if hovering { resetIdleTimerAction() }
            }
        }
    }
    private func launchApp(_ appItem: AppItem) {
        print("Attempting to launch \(appItem.name)...")
        let ws = NSWorkspace.shared; let conf = NSWorkspace.OpenConfiguration(); var urlToOpen: URL?
        if let id = appItem.bundleIdentifier, !id.isEmpty, let url = ws.urlForApplication(withBundleIdentifier: id) { urlToOpen = url }
        else if let path = appItem.appPath { urlToOpen = URL(fileURLWithPath: path) }
        guard let finalUrl = urlToOpen else { print("Could not launch \(appItem.name): No valid ID or path."); return }
        ws.openApplication(at: finalUrl, configuration: conf) { _, err in
            if let err = err { print("Error launching \(appItem.name): \(err.localizedDescription)") }
            else { print("\(appItem.name) launched successfully.") }
        }
    }
}
