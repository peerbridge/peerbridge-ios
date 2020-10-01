import SwiftyRSA
import CryptoKit


public typealias PEMString = String


extension PEMString {
    static let publicKeyPrefix = "-----BEGIN RSA PUBLIC KEY-----"
    static let publicKeySuffix = "-----END RSA PUBLIC KEY-----"
    static let privateKeyPrefix = "-----BEGIN RSA PRIVATE KEY-----"
    static let privateKeySuffix = "-----END RSA PRIVATE KEY-----"
    
    var isPublicKey: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return  trimmed.hasPrefix(PEMString.publicKeyPrefix) &&
                trimmed.hasSuffix(PEMString.publicKeySuffix)
    }
    
    var isPrivateKey: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return  trimmed.hasPrefix(PEMString.privateKeyPrefix) &&
                trimmed.hasSuffix(PEMString.privateKeySuffix)
    }
    
    var infix: String? {
        if isPublicKey {
            return self
                .replacingOccurrences(of: PEMString.publicKeyPrefix, with: "")
                .replacingOccurrences(of: PEMString.publicKeySuffix, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if isPrivateKey {
            return self
                .replacingOccurrences(of: PEMString.privateKeyPrefix, with: "")
                .replacingOccurrences(of: PEMString.privateKeySuffix, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}


extension PrivateKey: Hashable {
    public static func == (lhs: PrivateKey, rhs: PrivateKey) -> Bool {
        return lhs.reference == rhs.reference
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(reference)
    }
}


extension PublicKey: Hashable {
    public static func == (lhs: PublicKey, rhs: PublicKey) -> Bool {
        return lhs.reference == rhs.reference
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(reference)
    }
}


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
