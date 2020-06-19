import Foundation
import CryptoKit
import CommonCrypto
import SwiftyRSA

public extension SymmetricKey {
    var data: Data {
        self.withUnsafeBytes { unsafeRawBufferPointer -> Data in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            return Data(buffer: unsafeBufferPointer)
        }
    }
}

public struct RSAKeyPair: Codable {
    let privateKey: PrivateKey
    let publicKey: PublicKey

    private enum CodingKeys: String, CodingKey {
        case privateKey, publicKey
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let privateKeyString = try privateKey.pemString()
        let publicKeyString = try publicKey.pemString()
        try container.encode(privateKeyString, forKey: .privateKey)
        try container.encode(publicKeyString, forKey: .publicKey)
    }

    public init(privateKey: PrivateKey, publicKey: PublicKey) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let privateKeyString = try values.decode(String.self, forKey: .privateKey)
        let publicKeyString = try values.decode(String.self, forKey: .publicKey)
        self.privateKey = try PrivateKey(pemEncoded: privateKeyString)
        self.publicKey = try PublicKey(pemEncoded: publicKeyString)
    }
}

public final class Encryption {
    public static func createRandomNonce() -> Data {
        var nonce = Data(count: 256)
        let result = nonce.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, 256, pointer.baseAddress!)
        }
        
        guard result == errSecSuccess else { fatalError() }
        
        return nonce
    }
    
    public static func createRandomSymmetricKey() -> Data {
        return SymmetricKey(size: .bits256).data
    }

    public static func encrypt(
        data: Data,
        symmetricallyWithKeyData keyData: Data
    ) throws -> Data? {
        let key = SymmetricKey(data: keyData)
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        return sealedBox.combined
    }

    public static func decrypt(
        data: Data,
        symmetricallyWithKeyData keyData: Data
    ) throws -> Data {
        let key = SymmetricKey(data: keyData)
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }

    public static func createRandomAsymmetricKeyPair() throws -> RSAKeyPair {
        let keyPair = try SwiftyRSA.generateRSAKeyPair(sizeInBits: 2048)
        return .init(privateKey: keyPair.privateKey, publicKey: keyPair.publicKey)
    }

    public static func encrypt(
        data: Data,
        asymmetricallyWithPublicKey publicKey: PublicKey
    ) throws -> Data {
        let clear = ClearMessage(data: data)
        let encrypted = try clear.encrypted(with: publicKey, padding: .OAEP)
        return encrypted.data
    }

    public static func decrypt(
        data: Data,
        asymmetricallyWithPrivateKey privateKey: PrivateKey
    ) throws -> Data {
        let encrypted = EncryptedMessage(data: data)
        let decrypted = try encrypted.decrypted(with: privateKey, padding: .OAEP)
        return decrypted.data
    }

    // TODO: Signatures
}
