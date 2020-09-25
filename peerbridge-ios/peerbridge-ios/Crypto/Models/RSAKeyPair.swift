import SwiftyRSA


public typealias PEMString = String


public struct RSAKeyPair: Codable {
    let privateKey: PrivateKey
    let publicKey: PublicKey

    private enum CodingKeys: String, CodingKey {
        case privateKey, publicKey
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let privateKeyString: PEMString = try privateKey.pemString()
        let publicKeyString: PEMString = try publicKey.pemString()
        try container.encode(privateKeyString, forKey: .privateKey)
        try container.encode(publicKeyString, forKey: .publicKey)
    }

    public init(privateKey: PrivateKey, publicKey: PublicKey) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let privateKeyString = try values.decode(PEMString.self, forKey: .privateKey)
        let publicKeyString = try values.decode(PEMString.self, forKey: .publicKey)
        self.privateKey = try PrivateKey(pemEncoded: privateKeyString)
        self.publicKey = try PublicKey(pemEncoded: publicKeyString)
    }
}
