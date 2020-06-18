import Foundation

struct Endpoint {
    static var main: String {
        set {
            UserDefaults.standard.set(newValue, forKey: "endpoint")
        }
        get {
            if let main = UserDefaults.standard.string(forKey: "endpoint") {
                return main
            } else {
                let main = "http://localhost:8080"
                UserDefaults.standard.set(main, forKey: "endpoint")
                return main
            }
        }
    }
}
