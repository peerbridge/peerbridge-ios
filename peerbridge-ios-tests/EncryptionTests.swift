import XCTest
import CryptoKit
@testable import peerbridge_ios

class EncryptionTest: XCTestCase {
    func testSymmetricEncryption() throws {
        let clearText = "Yaaarrrnnn"
        let clearTextData = clearText.data(using: .utf8)!
        let keyData = Crypto.createRandomSymmetricKey()
        let encryptedData = try Crypto.encrypt(
            data: clearTextData, symmetricallyWithKeyData: keyData
        )
        let decryptedData = try Crypto.decrypt(
            data: encryptedData, symmetricallyWithKeyData: keyData
        )
        XCTAssertEqual(decryptedData, clearTextData)
    }

    func testAsymmetricKeyPairSerialization() throws {
        let keyPair = try Crypto.createRandomAsymmetricKeyPair()
        let serializedData = try JSONEncoder().encode(keyPair)
        let deserializedKeyPair = try JSONDecoder().decode(
            RSAKeyPair.self, from: serializedData
        )
        XCTAssertEqual(
            deserializedKeyPair.privateKey.pemString,
            keyPair.privateKey.pemString
        )
        XCTAssertEqual(
            deserializedKeyPair.publicKey.pemString,
            keyPair.publicKey.pemString
        )        
    }
    
    func testAsymmetricEncryption() throws {
        let keypair = try! Crypto.createRandomAsymmetricKeyPair()
        let message = "Lungo".data(using: .utf8)!
        let encryptedMessage = try Crypto.encrypt(
            data: message,
            asymmetricallyWithPublicKey: keypair.publicKey.key
        )
        let decryptedMessage = try Crypto.decrypt(
            data: encryptedMessage,
            asymmetricallyWithPrivateKey: keypair.privateKey.key
        )
        XCTAssertEqual(message, decryptedMessage)
    }
}
