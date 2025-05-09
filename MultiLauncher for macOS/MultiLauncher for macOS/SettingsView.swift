
// MARK: - SettingsView.swift
// Purpose: Provides UI for managing app settings.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingDuplicateAppAlert = false
    @State private var tempShortcutKeyCharacter: String = ""
    @State private var selectedAppIDsForDeletion = Set<AppItem.ID>()
    // isListInEditMode and EditButton related properties are removed as they are iOS-specific.
    // On macOS, .onMove enables drag-and-drop for reordering directly.

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Launcher Settings")
                    .font(.title)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label:
                    Text("Manage Apps").font(.title3) // Simpler label, reordering is via drag-and-drop
                    .padding(.bottom, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ) {
                    List(selection: $selectedAppIDsForDeletion) {
                        ForEach(settings.apps) { app in
                            HStack {
                                app.getAppIcon().resizable().frame(width: 32, height: 32)
                                Text(app.name).font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .tag(app.id)
                        }
                        .onMove(perform: settings.moveApp) // Enables drag-and-drop reordering
                        .onDelete(perform: settings.deleteApps) // Enables swipe-to-delete
                    }
                    // Removed .environment(\.editMode, ...)
                    .frame(minHeight: 200, maxHeight: 400)
                    
                    HStack {
                        Button(action: presentAddAppPanelInSettings) { Label("Add App", systemImage: "plus.circle.fill") }
                        Spacer()
                        Button(action: {
                            if !selectedAppIDsForDeletion.isEmpty {
                                settings.apps.removeAll { selectedAppIDsForDeletion.contains($0.id) }
                                selectedAppIDsForDeletion.removeAll()
                            }
                        }) { Label("Delete Selected", systemImage: "trash.fill")}
                        .disabled(selectedAppIDsForDeletion.isEmpty)
                    }
                    .padding(.top, 8)
                }
                .alert("Duplicate Application", isPresented: $showingDuplicateAppAlert) { Button("OK", role: .cancel) {} }
                message: { Text("The selected application is already in your launcher.") }

                GroupBox(label: Text("Appearance").font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 5)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { Text("Icons per row:"); Spacer(); Stepper("\(settings.columnsInGrid)", value: $settings.columnsInGrid, in: 1...10)}
                        HStack { Text("Icon Size:"); Spacer(); Stepper("\(Int(settings.iconSize))", value: $settings.iconSize, in: 48...128, step: 8)}
                        HStack { Text("Icon Spacing:"); Spacer(); Stepper("\(Int(settings.iconPadding))", value: $settings.iconPadding, in: 10...50, step: 5)}
                        HStack {
                            Text("Idle Hide Delay (seconds):")
                            Spacer()
                            TextField("", value: $settings.idleHideDelaySeconds, formatter: NumberFormatter.decimal)
                                .frame(width: 60)
                                .multilineTextAlignment(.trailing)
                            Text("(0 to disable)")
                        }
                    }
                }
                
                GroupBox(label: Text("Activation Shortcut").font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 5)) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Current Shortcut:")
                            Spacer()
                            Text(settings.activationHotkeyDisplayString).bold()
                        }
                        HStack(spacing: 10) {
                            Text("Modifiers:")
                            Spacer()
                            Toggle("⌘", isOn: $settings.shortcutModifierCommand).labelsHidden().toggleStyle(.checkbox)
                            Toggle("⌥", isOn: $settings.shortcutModifierOption).labelsHidden().toggleStyle(.checkbox)
                            Toggle("⌃", isOn: $settings.shortcutModifierControl).labelsHidden().toggleStyle(.checkbox)
                            Toggle("⇧", isOn: $settings.shortcutModifierShift).labelsHidden().toggleStyle(.checkbox)
                        }
                        .padding(.top, 5)


                        HStack {
                            Text("Key:")
                            Spacer()
                            TextField("Single Character", text: $tempShortcutKeyCharacter)
                                .frame(width: 120)
                                .multilineTextAlignment(.trailing)
                                .onAppear { tempShortcutKeyCharacter = settings.shortcutKeyCharacter }
                                .onChange(of: tempShortcutKeyCharacter) { newValue in
                                    let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                                    var charToSet = ""
                                    if let lastChar = filtered.last {
                                        charToSet = String(lastChar).uppercased()
                                    }
                                    // Update AppSettings.shortcutKeyCharacter, which will then trigger
                                    // updateKeyCodeFromCharacter and notify AppDelegate.
                                    if settings.shortcutKeyCharacter != charToSet {
                                        settings.shortcutKeyCharacter = charToSet
                                    }
                                    // Ensure temp field reflects the processed character
                                    if tempShortcutKeyCharacter != charToSet {
                                         tempShortcutKeyCharacter = charToSet
                                    }
                                }
                        }
                        .help("Enter a single letter or number.")

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Changes to shortcut take effect immediately.").font(.caption).foregroundColor(.green)
                            Text("IMPORTANT: If hotkey doesn't work:").bold().font(.caption).foregroundColor(.red).padding(.top)
                            Text("1. Check System Settings > Privacy & Security > Accessibility.").font(.caption).foregroundColor(.orange)
                            Text("2. Ensure MultiLauncher for macOS is listed AND ENABLED.").font(.caption).foregroundColor(.orange)
                            Text("3. You may need to add it manually (+) and then enable it. A restart of this app might be needed after changing permissions.").font(.caption).foregroundColor(.orange)
                            Text("4. The hotkey might be in use by another application.").font(.caption).foregroundColor(.orange)
                            Text("5. Try a very unique shortcut combination for testing (e.g., Ctrl+Opt+Shift+Cmd + a rare key like 'K' or 'J').") .font(.caption).foregroundColor(.orange)
                        }.padding(.top, 5)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 550, idealWidth:600, maxWidth: 700, minHeight: 700, idealHeight: 850, maxHeight: 1000)
        .navigationTitle("Launcher Preferences")
    }

    private func presentAddAppPanelInSettings() {
        let panel = NSOpenPanel(); panel.canChooseFiles = true; panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false; panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications/")
        panel.begin { rsp in if rsp == .OK, let url = panel.url { if !settings.addAppFromURL(url) { showingDuplicateAppAlert = true } } }
    }
}

// Helper for NumberFormatter in SettingsView
extension NumberFormatter {
    static var decimal: NumberFormatter {
        let formatter = NumberFormatter(); formatter.numberStyle = .decimal; formatter.minimum = 0; return formatter
    }
}

// Helper extension to get app name from Bundle
extension Bundle {
    var appName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
