import SwiftyRSA
import CryptoKit


public typealias PEMString = String


public struct RSAKeyPair: Codable, Hashable, Equatable {
    let privateKey: RSAPrivateKey
    let publicKey: RSAPublicKey
}
