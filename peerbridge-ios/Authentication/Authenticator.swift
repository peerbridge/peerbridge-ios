import Foundation
import LocalAuthentication
import secp256k1_implementation


public final class Authenticator {
    public struct KeyPair: Codable {
        let publicKey: String
        let privateKey: String
    }

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

    public static func newKeyPair() -> KeyPair {
        let key = secp256k1.Signing.PrivateKey()
        let privateKey = String(byteArray: key.rawRepresentation)
        let publicKey = String(byteArray: key.publicKey.rawRepresentation)
        return .init(publicKey: publicKey, privateKey: privateKey)
    }
    
    public static func loadKeyPair() throws -> KeyPair {
        let publicKey = try loadPublicKey()
        let privateKey = try loadPrivateKey(for: publicKey)
        return KeyPair(publicKey: publicKey, privateKey: privateKey)
    }
    
    public static func loadPublicKey() throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.peerbridge.keys.secp256k1.publickey",
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
    
    public static func loadPrivateKey(for publicKey: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: publicKey,
            kSecAttrService: "com.peerbridge.keys.secp256k1.privatekey",
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: true,
            kSecUseOperationPrompt: "Access your secp256k1 private key from the keychain",
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
    
    public static func register(newKeyPair keyPair: KeyPair) throws {
        try register(publicKey: keyPair.publicKey)
        try register(privateKey: keyPair.privateKey, forPublicKey: keyPair.publicKey)
    }
        
    private static func register(publicKey: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.peerbridge.keys.secp256k1.publickey",
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
    
    private static func register(privateKey: String, forPublicKey publicKey: String) throws {
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
            kSecAttrService: "com.peerbridge.keys.secp256k1.privatekey",
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
