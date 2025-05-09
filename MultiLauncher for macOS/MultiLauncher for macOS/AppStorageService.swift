
// MARK: - AppStorageService.swift
// Purpose: Handles saving and loading the list of AppItems using UserDefaults.

import Foundation

class AppStorageService {
    static let shared = AppStorageService()
    private let appsKey = "userAddedApps"
    private init() {}
    func loadApps() -> [AppItem] {
        guard let data = UserDefaults.standard.data(forKey: appsKey) else { return [] }
        do { return try JSONDecoder().decode([AppItem].self, from: data) }
        catch { print("Error decoding apps: \(error.localizedDescription)"); return [] }
    }
    func saveApps(_ apps: [AppItem]) {
        do { UserDefaults.standard.set(try JSONEncoder().encode(apps), forKey: appsKey) }
        catch { print("Error encoding apps: \(error.localizedDescription)") }
    }
}
