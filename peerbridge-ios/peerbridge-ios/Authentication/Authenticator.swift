import Foundation
import LocalAuthentication
import SwiftyRSA


public final class Authenticator {
    public enum Error: Swift.Error {
        case noKeyPair
        case decodingFailed
        case keychainFailed(OSStatus)
        
        var localizedDescription: String {
            switch self {
            case .decodingFailed:
                return "Decoding failed."
            case .noKeyPair:
                return "No keypair registered."
            case .keychainFailed(let status):
                guard
                    let description = SecCopyErrorMessageString(status, nil) as String?
                else { return "Unknown Error" }
                return description
            }
        }
    }
    
    public static func loadKeyPair() throws -> RSAKeyPair {
        let publicKeyString = try loadPublicKey()
        let privateKeyString = try loadPrivateKey(for: publicKeyString)
        let publicKey = try PublicKey(pemEncoded: publicKeyString)
        let privateKey = try PrivateKey(pemEncoded: privateKeyString)
        return RSAKeyPair(privateKey: privateKey, publicKey: publicKey)
    }
    
    public static func loadPublicKey() throws -> PEMString {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.peerbridge.keys.publickey",
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecReturnData: true,
            kSecReturnAttributes: true,
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else { throw Error.noKeyPair }
        guard status == errSecSuccess else { throw Self.Error.keychainFailed(status) }
        
        guard
            let existingItem = result as? [CFString: Any],
            let data = existingItem[kSecValueData] as? Data,
            let pemString = String(data: data, encoding: .utf8)
        else { throw Self.Error.decodingFailed }
        return pemString
    }
    
    public static func loadPrivateKey(for publicKey: PEMString) throws -> PEMString {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: publicKey,
            kSecAttrService: "com.peerbridge.keys.privatekey",
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: true,
            kSecUseOperationPrompt: "Access your private key from the keychain",
            kSecReturnData: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status != errSecItemNotFound else { throw Error.noKeyPair }
        guard status == errSecSuccess else { throw Self.Error.keychainFailed(status) }
        
        guard
            let existingItem = result as? [CFString: Any],
            let data = existingItem[kSecValueData] as? Data,
            let pemString = String(data: data, encoding: .utf8)
        else { throw Self.Error.decodingFailed }
        return pemString
    }
    
    public static func register(newKeyPair keyPair: RSAKeyPair) throws {
        let publicKeyString: PEMString = try keyPair.publicKey.pemString()
        let privateKeyString: PEMString = try keyPair.privateKey.pemString()
        try register(publicKey: publicKeyString)
        try register(privateKey: privateKeyString, forPublicKey: publicKeyString)
    }
        
    private static func register(publicKey: PEMString) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.peerbridge.keys.publickey",
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData: publicKey.data(using: String.Encoding.utf8)!
        ]
        
        var status = SecItemDelete(query as CFDictionary)
        guard
            status == errSecSuccess || // if the public key will be overridden
            status == errSecItemNotFound // if there was no registered public key
        else { throw Self.Error.keychainFailed(status) }
        
        status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw Self.Error.keychainFailed(status) }
    }
    
    private static func register(privateKey: PEMString, forPublicKey publicKey: PEMString) throws {
        let access = SecAccessControlCreateWithFlags(
            nil, // Use the default allocator
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .userPresence,
            nil // Ignore any error
        )
        
        // Explicitly disallow a device unlock in the last seconds
        // to be used as an authentication method, since another user
        // could social engineer the owner of the device to unlock
        // it for him in the excuse of looking into another app
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: publicKey,
            kSecAttrService: "com.peerbridge.keys.privatekey",
            kSecAttrAccessControl: access as Any,
            kSecUseAuthenticationContext: context,
            kSecValueData: privateKey.data(using: String.Encoding.utf8)!
        ]
        
        var status = SecItemDelete(query as CFDictionary)
        guard
            status == errSecSuccess || // if the private key will be overridden
            status == errSecItemNotFound // if there was no registered private key
        else { throw Self.Error.keychainFailed(status) }
        
        status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw Self.Error.keychainFailed(status) }
    }
}
