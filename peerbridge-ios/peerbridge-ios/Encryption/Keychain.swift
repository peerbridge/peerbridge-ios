import Foundation

public final class Keychain {
    public enum KeychainError: Error {
        case updateFailed
        case saveFailed
        case deleteFailed
    }

    public static func delete(dataForKey key: String) throws {
        let query = keychainQuery(withKey: key)
        guard SecItemCopyMatching(query, nil) == noErr else { return }
        guard SecItemDelete(query) == noErr else { throw KeychainError.deleteFailed }
    }

    public static func save(_ data: Data, forKey key: String) throws {
        let query = keychainQuery(withKey: key)
        if SecItemCopyMatching(query, nil) == noErr {
            guard
                SecItemUpdate(query, NSDictionary(dictionary: [kSecValueData: data])) == noErr
            else { throw KeychainError.updateFailed }
        } else {
            query.setValue(data, forKey: kSecValueData as String)
            guard
                SecItemAdd(query, nil) == noErr
            else { throw KeychainError.saveFailed }
        }
    }

    public static func save(_ string: String, forKey key: String) throws {
        guard
            let data = string.data(using: .utf8, allowLossyConversion: false)
        else { throw KeychainError.saveFailed }
        try save(data, forKey: key)
    }

    public static func load(dataBehindKey key: String) -> Data? {
        let query = keychainQuery(withKey: key)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnAttributes as String)

        var result: CFTypeRef?

        guard
            SecItemCopyMatching(query, &result) == noErr,
            let resultsDict = result as? NSDictionary
        else { return nil }

        return resultsDict.value(forKey: kSecValueData as String) as? Data
    }

    public static func load(stringBehindKey key: String) -> String? {
        guard let data = load(dataBehindKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func keychainQuery(withKey key: String) -> NSMutableDictionary {
        let result = NSMutableDictionary()
        result.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        result.setValue(key, forKey: kSecAttrService as String)
        result.setValue(
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            forKey: kSecAttrAccessible as String
        )
        return result
    }
}
