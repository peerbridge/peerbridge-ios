
import Foundation


struct ContentMessage: Message {
    let type: String
    let content: String
    
    init(content: String) {
        self.type = "content"
        self.content = content
    }
    
    var shortDescription: String {
        content
    }
}
