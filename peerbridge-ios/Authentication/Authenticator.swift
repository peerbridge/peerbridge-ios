import Foundation
import LocalAuthentication
import CryptoKit

extension String {
    var hexBytes: [UInt8] {
        .init(sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        })
    }
}

extension Sequence where Element == UInt8 {
    var hexString: String {
        self.map { String(format: "%02hhx", $0) }.joined()
    }
}

public final class Authenticator {
    public struct KeyPair: Codable {
        let publicKey: String
        let privateKey: String

        init(pub: String, priv: String) {
            self.publicKey = pub
            self.privateKey = priv
        }

        init(pub: [UInt8], priv: [UInt8]) {
            publicKey = pub.hexString
            privateKey = priv.hexString
        }

        public enum Error: Swift.Error {
            case sharedSecretCreationFailed
            case sealedBoxCombinationFailed
            case signingFailed
        }

        public func sign(t: inout Transaction) throws {
            var dataStr = ""
            if let tdata = t.data {
                dataStr = tdata.map { String(format: "%02hhx", $0) }.joined()
            }

            let signatureInputStr = "id:\(t.id)|sender:\(t.sender)|receiver:\(t.receiver)|balance:\(t.balance)|timeUnixNano:\(t.timeUnixNano)|data:\(dataStr)|fee:\(t.fee)"
            let signatureInput = signatureInputStr.data(using: .utf8)!
            let digest = SHA256.hash(data: signatureInput)

            let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
            defer { secp256k1_context_destroy(context) }

            var signature = secp256k1_ecdsa_signature()

            guard secp256k1_ecdsa_sign(context, &signature, Array(digest), privateKey.hexBytes, nil, nil) == 1 else {
                throw CryptoKitError.incorrectParameterSize
            }

            let compactSignatureLength = 64
            var compactSignature = [UInt8](repeating: 0, count: compactSignatureLength)

            guard secp256k1_ecdsa_signature_serialize_compact(context, &compactSignature, &signature) == 1 else {
                throw Self.Error.signingFailed
            }

            let compactSigData = Data(bytes: &compactSignature, count: compactSignatureLength)
            let compactSigString = [UInt8](compactSigData).hexString

            t.signature = compactSigString
        }

        public func encrypt(data: Data, partner: String) throws -> Data {
            guard
                let sharedSecret = self.sharedSecret(withPartner: partner)
            else { throw Error.sharedSecretCreationFailed }
            let key = SymmetricKey(data: sharedSecret.hexBytes)
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            guard
                let combined = sealedBox.combined
            else { throw Self.Error.sealedBoxCombinationFailed }
            return combined
        }

        public func decrypt(data: Data, partner: String) throws -> Data {
            guard
                let sharedSecret = self.sharedSecret(withPartner: partner)
            else { throw Error.sharedSecretCreationFailed }
            let key = SymmetricKey(data: sharedSecret.hexBytes)
            let box = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(box, using: key)
        }

        private func sharedSecret(withPartner partner: String) -> String? {
            let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
            defer { secp256k1_context_destroy(context) }

            var partnerPubkey = secp256k1_pubkey()

            guard secp256k1_ec_pubkey_parse(
                context,
                &partnerPubkey,
                partner.hexBytes,
                partner.hexBytes.count
            ) == 1 else {
                return nil
            }

            let sharedSecret = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
            guard secp256k1_ecdh(
                context,
                sharedSecret,
                &partnerPubkey,
                self.privateKey.hexBytes,
                nil,
                nil
            ) == 1 else {
                return nil
            }

            var sharedSecretBytes: [UInt8] = []
            for i in 0..<32 {
                sharedSecretBytes.append(sharedSecret[i])
            }

            return sharedSecretBytes.hexString
        }
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
        // Initialize context
        let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))!

        // Destroy context after creation
        defer { secp256k1_context_destroy(context) }

        // Setup private and public key variables
        var pubkeyLen = 33
        var cPubkey = secp256k1_pubkey()
        var publicKeyBytes = [UInt8](repeating: 0, count: 33)

        var privateKeyData = Data(count: 32)
        let result = privateKeyData.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
        }
        guard result == errSecSuccess else {
            fatalError()
        }
        let privateKeyBytes = [UInt8](privateKeyData)

        // Verify the context and keys are setup correctly
        guard secp256k1_context_randomize(context, privateKeyBytes) == 1,
            secp256k1_ec_pubkey_create(context, &cPubkey, privateKeyBytes) == 1,
            secp256k1_ec_pubkey_serialize(context, &publicKeyBytes, &pubkeyLen, &cPubkey, UInt32(SECP256K1_EC_COMPRESSED)) == 1 else {
            fatalError()
        }

        return .init(pub: publicKeyBytes, priv: privateKeyBytes)
    }
    
    public static func loadKeyPair() throws -> KeyPair {
        let publicKey = try loadPublicKey()
        let privateKey = try loadPrivateKey(for: publicKey)
        return KeyPair(pub: publicKey, priv: privateKey)
    }
    
    public static func loadPublicKey() throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.peerbridge.keys.secp256k1.pubkey",
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
            kSecAttrService: "com.peerbridge.keys.secp256k1.privkey",
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
            kSecAttrService: "com.peerbridge.keys.secp256k1.pubkey",
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
            kSecAttrService: "com.peerbridge.keys.secp256k1.privkey",
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
