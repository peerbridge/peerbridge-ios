
import Foundation


struct ContentMessage: TransactionMessage {
    let typeIdentifier: String
    let content: String
    
    init(content: String) {
        self.typeIdentifier = "content"
        self.content = content
    }
    
    var shortDescription: String {
        content
    }
}
