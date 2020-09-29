import Foundation

public class ISO8601Decoder: JSONDecoder {
    public override init() {
        super.init()
        dateDecodingStrategy = .iso8601
    }
}
