import SwiftUI
import CryptoKit


struct IdentificationView: View {
    let key: RSAPublicKey
    
    @State var grid: [[Double]] = []
    @State var color: Color = .blue
    
    func generateGrid() {
        guard
            let values = key.md5?.map({ byte in Double(byte) / Double(255) })
        else { return }
        // an MD5 hash contains 16 bytes
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
            IdentificationView(key: .alicePublicKey)
                .frame(width: 100, height: 100)
            Spacer()
            IdentificationView(key: .bobPublicKey)
                .frame(width: 200, height: 200)
            Spacer()
            IdentificationView(key: .alicePublicKey)
                .frame(width: 50, height: 50)
            Spacer()
        }
    }
}
#endif
