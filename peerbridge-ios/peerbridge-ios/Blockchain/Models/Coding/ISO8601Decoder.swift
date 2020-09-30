import Foundation

public class ISO8601Decoder: JSONDecoder {
    enum Error: Swift.Error {
        case invalidDate(String)
    }
    
    public override init() {
        super.init()
        dateDecodingStrategy = .custom({ decoder -> Date in
            let container = try decoder.singleValueContainer()
            let datestring = try container.decode(String.self)
            let isoFormatter = ISO8601DateFormatter()
            
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: datestring) {
                return date
            }
            
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: datestring) {
                return date
            }
            
            throw Self.Error.invalidDate(datestring)
        })
    }
}
