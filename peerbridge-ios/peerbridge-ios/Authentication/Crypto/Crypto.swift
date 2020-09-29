import Foundation
import CryptoKit
import SwiftyRSA


public extension SymmetricKey {
    var data: Data {
        self.withUnsafeBytes { unsafeRawBufferPointer -> Data in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            return Data(buffer: unsafeBufferPointer)
        }
    }
}


public final class Crypto {
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
        print(sealedBox.tag)
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
        let encrypted = try clear.encrypted(with: publicKey, padding: .PKCS1)
        return encrypted.data
    }

    public static func decrypt(
        data: Data,
        asymmetricallyWithPrivateKey privateKey: PrivateKey
    ) throws -> Data {
        let encrypted = EncryptedMessage(data: data)
        let decrypted = try encrypted.decrypted(with: privateKey, padding: .PKCS1)
        return decrypted.data
    }

    // TODO: Signatures
}
