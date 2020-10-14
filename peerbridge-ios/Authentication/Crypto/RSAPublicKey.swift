
import Foundation
import CryptoKit
import SwiftyRSA


public struct RSAPublicKey: Codable, Hashable, Equatable {
    let key: PublicKey
    let pemString: PEMString
    
    var md5: [UInt8]? {
        guard let data = try? key.data() else { return nil }
        return Insecure.MD5.hash(data: data).map { $0 as UInt8 }
    }
    
    var md5String: String? {
        md5?.map { String(format: "%02hhx", $0) }.joined()
    }
    
    var shortDescription: String {
        String(md5String?.prefix(5) ?? "n/a")
    }

    private enum CodingKeys: String, CodingKey {
        case pemString
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.pemString, forKey: .pemString)
    }

    public init(publicKey: PublicKey) throws {
        self.key = publicKey
        self.pemString = try publicKey.pemString()
    }
    
    public init(publicKeyString: PEMString) throws {
        self.pemString = publicKeyString
        self.key = try PublicKey(pemEncoded: publicKeyString)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.pemString = try values.decode(PEMString.self, forKey: .pemString)
        self.key = try PublicKey(pemEncoded: pemString)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pemString)
    }
    
    public static func == (lhs: RSAPublicKey, rhs: RSAPublicKey) -> Bool {
        return lhs.pemString == rhs.pemString
    }
}
