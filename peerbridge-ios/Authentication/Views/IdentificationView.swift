import SwiftUI
import CryptoKit


struct IdentificationView: View {
    let key: String
    
    @State var grid: [[Double]] = []
    @State var color: Color = .blue
    
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
            IdentificationView(key: "0372689db204d56d9bb7122497eef4732cce308b73f3923fc076aed3c2dfa4ad04")
                .frame(width: 100, height: 100)
            Spacer()
            IdentificationView(key: "03f1f2fbd80b49b8ffc8194ac0a0e0b7cf0c7e21bca2482c5fba7adf67db41dec5")
                .frame(width: 200, height: 200)
            Spacer()
        }
    }
}
#endif
