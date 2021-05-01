import SwiftUI
import CryptoKit

fileprivate func randomColor(seed: String) -> UIColor {
    var total: Int = 0
    for u in seed.unicodeScalars {
        total += Int(UInt32(u))
    }

    srand48(total * 200)
    let r = CGFloat(drand48())

    srand48(total)
    let g = CGFloat(drand48())

    srand48(total / 200)
    let b = CGFloat(drand48())

    return UIColor(red: r, green: g, blue: b, alpha: 1)
}

struct IdentificationView: View {
    let key: String
    let color: Color
    
    @State var grid: [[Double]] = []

    init(key: String) {
        self.key = key
        self.color = Color(randomColor(seed: key))
    }
    
    func generateGrid() {
        guard
            let values = key.data(using: .ascii)?.map({ byte in Double(byte) / Double(255) })
        else { return }
        // The public key is more than 16 bytes long
        self.grid = [
            Array(values[0 ..< 4]),
            Array(values[4 ..< 8]),
            Array(values[8 ..< 12]),
            Array(values[12 ..< 16]),
        ]
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(grid, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(row, id: \.self) { column in
                        Rectangle().opacity(column).cornerRadius(4)
                    }
                }
            }
        }
        .foregroundColor(color)
        .onAppear(perform: generateGrid)
    }
}


#if DEBUG
struct IdentificationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            IdentificationView(key: AuthenticationEnvironment.random().keyPair.publicKey)
                .frame(width: 100, height: 100)
            Spacer()
            IdentificationView(key: "03f1f2fbd80b49b8ffc8194ac0a0e0b7cf0c7e21bca2482c5fba7adf67db41dec5")
                .frame(width: 200, height: 200)
            Spacer()
        }
    }
}
#endif
