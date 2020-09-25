import Foundation

public class ISO8601Encoder: JSONEncoder {
    public override init() {
        super.init()
        dateEncodingStrategy = .iso8601
    }
}
