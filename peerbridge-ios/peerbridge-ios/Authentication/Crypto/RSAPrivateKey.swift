import Foundation
import SwiftyRSA


public struct RSAPrivateKey: Codable, Hashable, Equatable {
    let key: PrivateKey
    let pemString: PEMString

    private enum CodingKeys: String, CodingKey {
        case pemString
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.pemString, forKey: .pemString)
    }

    public init(privateKey: PrivateKey) throws {
        self.key = privateKey
        self.pemString = try privateKey.pemString()
    }
    
    public init(privateKeyString: PEMString) throws {
        self.pemString = privateKeyString
        self.key = try PrivateKey(pemEncoded: privateKeyString)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.pemString = try values.decode(PEMString.self, forKey: .pemString)
        self.key = try PrivateKey(pemEncoded: pemString)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pemString)
    }
    
    public static func == (lhs: RSAPrivateKey, rhs: RSAPrivateKey) -> Bool {
        return lhs.pemString == rhs.pemString
    }
}
