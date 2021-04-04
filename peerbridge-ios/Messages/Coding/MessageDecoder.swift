
import Foundation


public class MessageDecoder {
    private let decoder: JSONDecoder
    
    public init() {
        self.decoder = JSONDecoder()
    }
    
    public func decode(from data: Data) -> TransactionMessage? {
        if let content = try? decoder.decode(ContentMessage.self, from: data) {
            return content
        } else if let token = try? decoder.decode(TokenMessage.self, from: data) {
            return token
        }
        return nil
    }
}
