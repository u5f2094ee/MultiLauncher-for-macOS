// MARK: - AppSettings.swift
// Purpose: Manages shared application settings and data, observable by views.

import SwiftUI
import Combine // For ObservableObject
import AppKit // For NSEvent key codes if we store them

class AppSettings: ObservableObject {
    let hotkeySettingsChanged = PassthroughSubject<Void, Never>()
    let idleTimerSettingsChanged = PassthroughSubject<Void, Never>()

    @Published var apps: [AppItem] { didSet { AppStorageService.shared.saveApps(apps) } }
    @Published var columnsInGrid: Int { didSet { UserDefaults.standard.set(columnsInGrid, forKey: "columnsInGrid") } }
    
    // --- Size Settings ---
    @Published var iconSize: CGFloat { didSet { UserDefaults.standard.set(iconSize, forKey: "iconSize") } }
    @Published var iconPadding: CGFloat { didSet { UserDefaults.standard.set(iconPadding, forKey: "iconPadding") } }
    // --- End Size Settings ---

    // --- Idle Timer Setting ---
    @Published var idleHideDelaySeconds: Double {
        didSet {
            UserDefaults.standard.set(idleHideDelaySeconds, forKey: "idleHideDelaySeconds")
            idleTimerSettingsChanged.send()
        }
    }
    // --- End Idle Timer Setting ---
    
    @Published var shortcutKeyCode: UInt16 {
        didSet {
            if oldValue != shortcutKeyCode {
                print("AppSettings: shortcutKeyCode DID CHANGE from \(oldValue) to \(shortcutKeyCode)")
                UserDefaults.standard.set(Int(shortcutKeyCode), forKey: "shortcutKeyCode")
                hotkeySettingsChanged.send()
            }
        }
    }
    @Published var shortcutKeyCharacter: String {
        didSet {
            if oldValue != shortcutKeyCharacter {
                print("AppSettings: shortcutKeyCharacter DID CHANGE from '\(oldValue)' to '\(shortcutKeyCharacter)'")
                UserDefaults.standard.set(shortcutKeyCharacter, forKey: "shortcutKeyCharacter")
                updateKeyCodeFromCharacter()
            }
        }
    }

    @Published var shortcutModifierCommand: Bool {
        didSet { if oldValue != shortcutModifierCommand { print("AppSettings: Command changed to \(shortcutModifierCommand)"); UserDefaults.standard.set(shortcutModifierCommand, forKey: "shortcutModifierCommand"); hotkeySettingsChanged.send() } }
    }
    @Published var shortcutModifierOption: Bool {
        didSet { if oldValue != shortcutModifierOption { print("AppSettings: Option changed to \(shortcutModifierOption)"); UserDefaults.standard.set(shortcutModifierOption, forKey: "shortcutModifierOption"); hotkeySettingsChanged.send() } }
    }
    @Published var shortcutModifierControl: Bool {
        didSet { if oldValue != shortcutModifierControl { print("AppSettings: Control changed to \(shortcutModifierControl)"); UserDefaults.standard.set(shortcutModifierControl, forKey: "shortcutModifierControl"); hotkeySettingsChanged.send() } }
    }
    @Published var shortcutModifierShift: Bool {
        didSet { if oldValue != shortcutModifierShift { print("AppSettings: Shift changed to \(shortcutModifierShift)"); UserDefaults.standard.set(shortcutModifierShift, forKey: "shortcutModifierShift"); hotkeySettingsChanged.send() } }
    }

    var shortcutModifierFlags: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if shortcutModifierCommand { flags.insert(.command) }
        if shortcutModifierOption { flags.insert(.option) }
        if shortcutModifierControl { flags.insert(.control) }
        if shortcutModifierShift { flags.insert(.shift) }
        return flags
    }
    
    var activationHotkeyDisplayString: String {
        var modifierString = ""
        if shortcutModifierControl { modifierString += "⌃" }
        if shortcutModifierOption { modifierString += "⌥" }
        if shortcutModifierShift { modifierString += "⇧" }
        if shortcutModifierCommand { modifierString += "⌘" }
        
        var keyStringPart = ""
        if !shortcutKeyCharacter.isEmpty {
            keyStringPart = shortcutKeyCharacter.uppercased()
        } else if let mappedKeyString = self.stringForKeyCode(self.shortcutKeyCode) {
            keyStringPart = mappedKeyString.uppercased()
        } else if shortcutKeyCode != 0 { // Only show "Key X" if a keycode is actually set and not mappable
             keyStringPart = "Key \(self.shortcutKeyCode)"
        }
        
        let fullDisplayString = modifierString + keyStringPart

        if fullDisplayString.isEmpty { // No key and no modifiers
            return "Not Set"
        } else if keyStringPart.isEmpty && !modifierString.isEmpty { // Only modifiers set, no key character
            return "\(modifierString) (No Key)"
        }
        return fullDisplayString
    }

    init() {
        let initialApps = AppStorageService.shared.loadApps()
        var initialColumnsInGrid = UserDefaults.standard.integer(forKey: "columnsInGrid")
        if initialColumnsInGrid == 0 { initialColumnsInGrid = 4 }

        var initialIconSize = CGFloat(UserDefaults.standard.double(forKey: "iconSize"))
        if initialIconSize < 48 { initialIconSize = 80 }

        var initialIconPadding = CGFloat(UserDefaults.standard.double(forKey: "iconPadding"))
        if initialIconPadding < 10 { initialIconPadding = 30 }

        let initialIdleHideDelay = UserDefaults.standard.double(forKey: "idleHideDelaySeconds")
        
        let initialShortcutKeyCode = UInt16(UserDefaults.standard.object(forKey: "shortcutKeyCode") as? Int ?? 37) // Default L
        let initialShortcutKeyCharacter = UserDefaults.standard.string(forKey: "shortcutKeyCharacter") ?? "L"

        let initialShortcutModifierCommand = UserDefaults.standard.object(forKey: "shortcutModifierCommand") as? Bool ?? true
        let initialShortcutModifierOption = UserDefaults.standard.object(forKey: "shortcutModifierOption") as? Bool ?? true
        let initialShortcutModifierControl = UserDefaults.standard.object(forKey: "shortcutModifierControl") as? Bool ?? false
        let initialShortcutModifierShift = UserDefaults.standard.object(forKey: "shortcutModifierShift") as? Bool ?? false

        self.apps = initialApps
        self.columnsInGrid = initialColumnsInGrid
        self.iconSize = initialIconSize
        self.iconPadding = initialIconPadding
        self.idleHideDelaySeconds = initialIdleHideDelay >= 0 ? initialIdleHideDelay : 5.0
        self.shortcutKeyCode = initialShortcutKeyCode
        self.shortcutKeyCharacter = initialShortcutKeyCharacter
        self.shortcutModifierCommand = initialShortcutModifierCommand
        self.shortcutModifierOption = initialShortcutModifierOption
        self.shortcutModifierControl = initialShortcutModifierControl
        self.shortcutModifierShift = initialShortcutModifierShift
        print("AppSettings Initialized: Code=\(self.shortcutKeyCode), Char='\(self.shortcutKeyCharacter)', Cmd=\(self.shortcutModifierCommand), Opt=\(self.shortcutModifierOption), Ctrl=\(self.shortcutModifierControl), Shift=\(self.shortcutModifierShift)")
    }

    func addAppFromURL(_ url: URL) -> Bool {
        let path = url.path
        guard let bundle = Bundle(url: url) else { print("Could not create bundle from URL: \(url)"); return false }
        let appName = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? url.deletingPathExtension().lastPathComponent
        let bundleIdentifier = bundle.bundleIdentifier
        let iconName = "app.fill"
        let newApp = AppItem(name: appName, iconName: iconName, bundleIdentifier: bundleIdentifier, appPath: path)
        let alreadyExists = apps.contains { existingApp in
            if let newId = newApp.bundleIdentifier, !newId.isEmpty, let oldId = existingApp.bundleIdentifier, !oldId.isEmpty { return newId == oldId }
            if let newPath = newApp.appPath, let oldPath = existingApp.appPath { return newPath == oldPath }
            return false
        }
        if !alreadyExists { apps.append(newApp); return true }
        else { print("App '\(newApp.name)' already exists."); return false }
    }
    
    func deleteApps(at offsets: IndexSet) { apps.remove(atOffsets: offsets) }
    
    func moveApp(from source: IndexSet, to destination: Int) {
        apps.move(fromOffsets: source, toOffset: destination)
    }
    
    func updateKeyCodeFromCharacter() {
        guard let firstChar = shortcutKeyCharacter.uppercased().first else {
            if self.shortcutKeyCode != 0 {
                print("AppSettings: shortcutKeyCharacter cleared, setting shortcutKeyCode to 0 (invalid).")
                self.shortcutKeyCode = 0
            }
            return
        }
        var newKeyCode: UInt16?
        switch firstChar {
            case "A": newKeyCode = 0; case "S": newKeyCode = 1; case "D": newKeyCode = 2; case "F": newKeyCode = 3;
            case "H": newKeyCode = 4; case "G": newKeyCode = 5; case "Z": newKeyCode = 6; case "X": newKeyCode = 7;
            case "C": newKeyCode = 8; case "V": newKeyCode = 9; case "B": newKeyCode = 11; case "Q": newKeyCode = 12;
            case "W": newKeyCode = 13; case "E": newKeyCode = 14; case "R": newKeyCode = 15; case "Y": newKeyCode = 16;
            case "T": newKeyCode = 17; case "I": newKeyCode = 34; case "O": newKeyCode = 31; case "U": newKeyCode = 32;
            case "J": newKeyCode = 38; case "K": newKeyCode = 40; case "L": newKeyCode = 37; case "P": newKeyCode = 35;
            case "N": newKeyCode = 45; case "M": newKeyCode = 46;
            case "1": newKeyCode = 18; case "2": newKeyCode = 19; case "3": newKeyCode = 20; case "4": newKeyCode = 21;
            case "5": newKeyCode = 23; case "6": newKeyCode = 22; case "7": newKeyCode = 26; case "8": newKeyCode = 28;
            case "9": newKeyCode = 25; case "0": newKeyCode = 29;
            default:
                print("No direct keycode mapping for character: \(firstChar). Setting shortcutKeyCode to 0 (invalid).")
                newKeyCode = 0
        }
        
        if let kc = newKeyCode {
            if self.shortcutKeyCode != kc {
                self.shortcutKeyCode = kc
            }
        } else {
            if self.shortcutKeyCode != 0 { self.shortcutKeyCode = 0 }
        }
    }

    private func stringForKeyCode(_ keyCode: UInt16) -> String? {
        if !shortcutKeyCharacter.isEmpty { return shortcutKeyCharacter }
        switch keyCode {
            case 0: return "A"; case 1: return "S"; case 2: return "D"; case 3: return "F";
            case 4: return "H"; case 5: return "G"; case 6: return "Z"; case 7: return "X";
            case 8: return "C"; case 9: return "V"; case 11: return "B"; case 12: return "Q";
            case 13: return "W"; case 14: return "E"; case 15: return "R"; case 16: return "Y";
            case 17: return "T"; case 34: return "I"; case 31: return "O"; case 32: return "U";
            case 38: return "J"; case 40: return "K"; case 37: return "L"; case 35: return "P";
            case 45: return "N"; case 46: return "M";
            case 18: return "1"; case 19: return "2"; case 20: return "3"; case 21: return "4";
            case 23: return "5"; case 22: return "6"; case 26: return "7"; case 28: return "8";
            case 25: return "9"; case 29: return "0";
            case 36: return "↩︎"; case 48: return "⇥"; case 49: return "Space";
            case 51: return "⌫"; case 53: return "Esc";
            case 123: return "←"; case 124: return "→"; case 125: return "↓"; case 126: return "↑";
            default: return nil
        }
    }
}

