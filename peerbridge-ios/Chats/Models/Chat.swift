import Foundation
import SwiftyRSA 


struct Chat: Codable, Hashable, Equatable, Identifiable {
    let partnerPublicKey: String
    let lastTransaction: Transaction?
    
    var id: String {
        partnerPublicKey
    }

    var shortHex: String {
        let index = partnerPublicKey.index(partnerPublicKey.startIndex, offsetBy: 6)
        return String(partnerPublicKey[..<index])
    }
}
