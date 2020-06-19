import Foundation

public class ISO8601Encoder: JSONEncoder {
    public override init() {
        super.init()
        dateEncodingStrategy = .iso8601
    }
}

public class ISO8601Decoder: JSONDecoder {
    public override init() {
        super.init()
        dateDecodingStrategy = .iso8601
    }
}
