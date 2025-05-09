
// MARK: - AppItem.swift
// Purpose: Defines the data model for an application.

import SwiftUI
import AppKit

struct AppItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    let bundleIdentifier: String?
    let appPath: String?

    init(id: UUID = UUID(), name: String, iconName: String = "app.fill", bundleIdentifier: String?, appPath: String?) {
        self.id = id; self.name = name; self.iconName = iconName; self.bundleIdentifier = bundleIdentifier; self.appPath = appPath
    }
    static func == (lhs: AppItem, rhs: AppItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    func getAppIcon() -> Image {
        if let path = appPath { return Image(nsImage: NSWorkspace.shared.icon(forFile: path)) }
        return Image(systemName: iconName)
    }
}
