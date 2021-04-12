
import Foundation


struct TokenMessage: Message {
    let typeIdentifier: String
    let token: NotificationToken
    
    init(token: NotificationToken) {
        self.typeIdentifier = "token"
        self.token = token
    }
    
    var shortDescription: String {
        "This user has shared a push notification token."
    }
}
