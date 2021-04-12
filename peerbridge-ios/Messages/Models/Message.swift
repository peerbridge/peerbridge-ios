
import Foundation
import CryptoKit

public protocol Message: Codable {
    /// Messages must denote a type identifier string to avoid decoding ambiguity
    var typeIdentifier: String { get }
    
    /// Messages must give a short description for the chat view preview
    var shortDescription: String { get }
}
