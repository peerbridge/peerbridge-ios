import SwiftUI
import CryptoKit


fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}


fileprivate struct HashQuad {
    let opacity: Double
    let color: Color
}


struct IdentificationView: View {
    let key: String
    
    @State var grid: [[Double]] = []
    @State var color: Color = .white
    
    init(key: String) {
        self.key = key
    }
    
    func generateGrid() {
        let values = Insecure.MD5
            .hash(data: key.data(using: .utf8) ?? Data())
            .map { Double($0 as UInt8) / Double(255) }
        // an MD5 hash contains 16 bytes
        self.grid = [
            Array(values[0 ..< 4]),
            Array(values[4 ..< 8]),
            Array(values[8 ..< 12]),
            Array(values[12 ..< 16]),
        ]
        // use the first byte for the color hue
        self.color = Color(
            hue: values[0],
            saturation: 1,
            brightness: 0.8
        )
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(grid, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(row, id: \.self) { column in
                        Rectangle().opacity(column)
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
            IdentificationView(key: .alicePublicKeyString)
                .frame(width: 100, height: 100)
            Spacer()
            IdentificationView(key: .bobPublicKeyString)
                .frame(width: 200, height: 200)
            Spacer()
            IdentificationView(key: .alicePublicKeyString)
                .frame(width: 50, height: 50)
            Spacer()
        }
    }
}
#endif
