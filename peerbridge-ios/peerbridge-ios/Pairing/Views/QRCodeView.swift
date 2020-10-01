import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    @State var uri: String
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    var body: some View {
        Image(uiImage: generateQRCode(from: uri))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }
}


#if DEBUG
struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(uri: "peerbridge://test")
            .frame(width: 200, height: 200)
    }
}
#endif
