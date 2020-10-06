
import Foundation


public typealias PushNotificationToken = String


public final class ChatKeychain {
    public enum Error: Swift.Error {
        case itemNotFound
        case decodingFailed
        case keychainFailed(OSStatus)
    }
    
    public static func loadPushNotificationToken(
        forPartner partner: PEMString
    ) throws -> PushNotificationToken {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: partner,
            kSecAttrService: "com.peerbridge.keys.push",
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecReturnData: true,
            kSecReturnAttributes: true,
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else { throw Self.Error.itemNotFound }
        guard status == errSecSuccess else { throw Self.Error.keychainFailed(status) }
        
        guard
            let existingItem = result as? [CFString: Any],
            let data = existingItem[kSecValueData] as? Data,
            let token = String(data: data, encoding: .utf8)
        else { throw Self.Error.decodingFailed }
        return token
    }
        
    public static func register(
        token: PushNotificationToken,
        forPartner partner: PEMString
    ) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: partner,
            kSecAttrService: "com.peerbridge.keys.push",
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData: token.data(using: String.Encoding.utf8)!
        ]
        
        var status = SecItemDelete(query as CFDictionary)
        guard
            status == errSecSuccess || // if the public key will be overridden
            status == errSecItemNotFound // if there was no registered public key
        else { throw Self.Error.keychainFailed(status) }
        
        status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw Self.Error.keychainFailed(status) }
    }
}
