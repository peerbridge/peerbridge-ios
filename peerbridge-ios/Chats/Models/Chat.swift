import Foundation
import SwiftyRSA 


struct Chat: Codable, Hashable, Equatable, Identifiable {
    let partnerPublicKey: RSAPublicKey
    let lastTransaction: Transaction?
    
    var id: String {
        partnerPublicKey.pemString
    }
}
