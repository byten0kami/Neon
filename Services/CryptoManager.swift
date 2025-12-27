import Foundation
import CryptoKit
import Security

/// Manages data encryption and decryption using a symmetric key stored in the Keychain.
@MainActor
class CryptoManager {
    static let shared = CryptoManager()
    
    private let keychainAccount = "neurosync_data_key"
    private var symmetricKey: SymmetricKey?
    
    private init() {
        self.symmetricKey = retrieveOrGenerateKey()
    }
    
    /// Encrypts data using AES-GCM
    func encrypt(_ data: Data) throws -> Data {
        guard let key = symmetricKey else {
            throw CryptoError.keyMissing
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    /// Decrypts data using AES-GCM
    func decrypt(_ data: Data) throws -> Data {
        guard let key = symmetricKey else {
            throw CryptoError.keyMissing
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Key Management
    
    private func retrieveOrGenerateKey() -> SymmetricKey? {
        if let existingKey = readKeyFromKeychain() {
            // Verify/Migrate accessibility attribute
            migrateKeyAttributeIfNeeded()
            return existingKey
        }
        
        let newKey = SymmetricKey(size: .bits256)
        saveKeyToKeychain(newKey)
        return newKey
    }
    
    /// Deletes the symmetric key from the keychain
    func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        symmetricKey = nil
    }
    
    private func saveKeyToKeychain(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            // Updated attribute: Accessible only when unlocked, and not included in usage-encrypted backups
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary) // Delete any existing item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Error saving key to keychain: \(status)")
        }
    }
    
    /// Migrates existing keys to the new security attribute
    private func migrateKeyAttributeIfNeeded() {
        // Attempt to update the item's attribute
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        // errSecSuccess means updated (or was already correct enough to not fail, though SecItemUpdate usually updates)
        // errSecItemNotFound means no item (shouldn't happen here as we just read it)
        if status != errSecSuccess {
             // If update fails, re-saving is the fallback, but since we have the key in memory (from readKeyFromKeychain),
             // we can't easily re-save `existingKey` here without passing it in.
             // However, `SecItemUpdate` is the standard way. If it fails, we log it.
             // We don't want to be destructive here.
             print("Keychain migration warning: Status \(status)")
        }
    }
    
    private func readKeyFromKeychain() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return SymmetricKey(data: data)
        }
        
        return nil
    }
}

enum CryptoError: Error {
    case keyMissing
    case encryptionFailed
    case decryptionFailed
}
