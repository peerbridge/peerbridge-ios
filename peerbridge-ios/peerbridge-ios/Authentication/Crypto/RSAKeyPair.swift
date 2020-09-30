import SwiftyRSA


public typealias PEMString = String


public struct RSAKeyPair: Codable {
    let privateKey: PrivateKey
    let privateKeyString: PEMString
    let publicKey: PublicKey
    let publicKeyString: PEMString

    private enum CodingKeys: String, CodingKey {
        case privateKey, publicKey
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.privateKeyString, forKey: .privateKey)
        try container.encode(self.publicKeyString, forKey: .publicKey)
    }

    public init(privateKey: PrivateKey, publicKey: PublicKey) throws {
        self.privateKey = privateKey
        self.privateKeyString = try privateKey.pemString()
        self.publicKey = publicKey
        self.publicKeyString = try publicKey.pemString()
    }
    
    public init(privateKeyString: PEMString, publicKeyString: PEMString) throws {
        self.privateKeyString = privateKeyString
        self.privateKey = try PrivateKey(pemEncoded: privateKeyString)
        self.publicKeyString = publicKeyString
        self.publicKey = try PublicKey(pemEncoded: publicKeyString)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.privateKeyString = try values.decode(PEMString.self, forKey: .privateKey)
        self.publicKeyString = try values.decode(PEMString.self, forKey: .publicKey)
        self.privateKey = try PrivateKey(pemEncoded: privateKeyString)
        self.publicKey = try PublicKey(pemEncoded: publicKeyString)
    }
}
