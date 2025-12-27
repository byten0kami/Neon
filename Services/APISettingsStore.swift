import Foundation
import Security
import Combine
import SwiftUI

// MARK: - API Settings Store

/// Manages API settings with secure Keychain storage for API keys
/// Settings (non-sensitive) stored in UserDefaults, API key in Keychain
@MainActor
class APISettingsStore: ObservableObject {
    static let shared = APISettingsStore()
    
    // MARK: - Published Properties
    
    @Published private(set) var settings: APISettings {
        didSet { saveSettings() }
    }
    
    // MARK: - Private Properties
    
    private let settingsKey = "neon.api.settings"
    private let keychainService = "com.neon.api"
    private let keychainAccount = "openrouter-api-key"
    
    // MARK: - Initialization
    
    private init() {
        self.settings = Self.loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Update settings
    func updateSettings(_ settings: APISettings) {
        self.settings = settings
    }
    
    /// Toggle custom key usage
    func setUseCustomKey(_ enabled: Bool) {
        settings.useCustomKey = enabled
    }
    
    /// Set selected model
    func setSelectedModel(_ model: String) {
        settings.selectedModel = model
    }
    
    /// Set default defer time in minutes
    func setDefaultDeferMinutes(_ minutes: Int) {
        settings.defaultDeferMinutes = minutes
    }
    
    /// Set card layout mode
    func setCardLayoutMode(_ mode: APISettings.CardLayoutMode) {
        settings.cardLayoutMode = mode
    }
    
    /// Get the effective API key (user's custom key if enabled)
    func getEffectiveAPIKey() -> String? {
        guard settings.useCustomKey else { return nil }
        return getAPIKeyFromKeychain()
    }
    
    /// Save API key to Keychain
    func saveAPIKey(_ key: String) -> Bool {
        // Delete existing key first
        deleteAPIKey()
        
        guard let data = key.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Get API key from Keychain
    func getAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Delete API key from Keychain
    @discardableResult
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Check if user has a custom API key stored
    func hasCustomAPIKey() -> Bool {
        return getAPIKeyFromKeychain() != nil
    }
    
    // MARK: - Private Methods
    
    private static func loadSettings() -> APISettings {
        guard let data = UserDefaults.standard.data(forKey: "neon.api.settings"),
              let settings = try? JSONDecoder().decode(APISettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: settingsKey)
    }
}
