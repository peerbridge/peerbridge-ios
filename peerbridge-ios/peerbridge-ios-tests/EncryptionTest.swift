import XCTest
import CryptoKit
@testable import peerbridge_ios

class EncryptionTest: XCTestCase {
    func testSymmetricEncryption() throws {
        let clearText = "Yaaarrrnnn"
        let clearTextData = clearText.data(using: .utf8)!
        let keyData = Encryption.createRandomSymmetricKey()
        let encryptedData = try Encryption.encrypt(
            data: clearTextData, symmetricallyWithKeyData: keyData
        )
        XCTAssertNotNil(encryptedData)
        let decryptedData = try Encryption.decrypt(
            data: encryptedData!, symmetricallyWithKeyData: keyData
        )
        XCTAssertEqual(decryptedData, clearTextData)
    }

    func testAsymmetricKeyPairSerialization() throws {
        let keyPair = try Encryption.createRandomAsymmetricKeyPair()
        let serializedData = try JSONEncoder().encode(keyPair)
        let deserializedKeyPair = try JSONDecoder().decode(RSAKeyPair.self, from: serializedData)
        XCTAssertEqual(
            try deserializedKeyPair.privateKey.pemString(),
            try keyPair.privateKey.pemString()
        )
        XCTAssertEqual(
            try deserializedKeyPair.publicKey.pemString(),
            try keyPair.publicKey.pemString()
        )
    }
}
