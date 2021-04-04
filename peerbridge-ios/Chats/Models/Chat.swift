import Foundation
import SwiftyRSA 


struct Chat: Codable, Hashable, Equatable, Identifiable {
    let partnerPublicKey: String
    let lastTransaction: Transaction?
    
    var id: String {
        partnerPublicKey
    }
}
