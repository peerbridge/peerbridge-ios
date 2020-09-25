import Foundation
import LocalAuthentication
import SwiftyRSA


public final class Authenticator {
    public struct KeychainError: Error {
        var status: OSStatus
        
        var localizedDescription: String {
            guard
                let description =  SecCopyErrorMessageString(status, nil) as String?
            else { return "Unknown Error" }
            return description
        }
    }
    
    public enum CodingError: Error {
        case decodingFailed
    }
    
    public static func loadPublicKey() throws -> PEMString {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.peerbridge.keys.public",
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecReturnData: true,
            kSecReturnAttributes: true,
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        
        guard
            let existingItem = result as? [CFString: Any],
            let data = existingItem[kSecValueData] as? Data,
            let pemString = String(data: data, encoding: .utf8)
        else { throw CodingError.decodingFailed }
        return pemString
    }
    
    public static func loadPrivateKey(for publicKey: PEMString) throws -> PEMString {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: publicKey,
            kSecAttrService: "com.peerbridge.keys.private",
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnAttributes: true,
            kSecUseOperationPrompt: "Access your credentials from the keychain",
            kSecReturnData: true
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        
        guard
            let existingItem = result as? [CFString: Any],
            let data = existingItem[kSecValueData] as? Data,
            let pemString = String(data: data, encoding: .utf8)
        else { throw CodingError.decodingFailed }
        return pemString
    }
    
    public static func registerNewKeyPair() throws {
        let credentials = try Crypto.createRandomAsymmetricKeyPair()
        let publicKeyString: PEMString = try credentials.publicKey.pemString()
        let privateKeyString: PEMString = try credentials.privateKey.pemString()
        try register(publicKey: publicKeyString)
        try register(privateKey: privateKeyString, forPublicKey: publicKeyString)
    }
    
    private static func register(publicKey: PEMString) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.peerbridge.keys.public",
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData: publicKey.data(using: String.Encoding.utf8)!
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
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
            kSecAttrService: "com.peerbridge.keys.private",
            kSecAttrAccessControl: access as Any,
            kSecUseAuthenticationContext: context,
            kSecValueData: privateKey.data(using: String.Encoding.utf8)!
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
}
