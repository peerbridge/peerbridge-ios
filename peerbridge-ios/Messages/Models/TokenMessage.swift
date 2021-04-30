
import Foundation


struct TokenMessage: Message {
    let type: String
    let token: NotificationToken
    
    init(token: NotificationToken) {
        self.type = "token"
        self.token = token
    }
    
    var shortDescription: String {
        "This user has shared a push notification token."
    }
}
