import SwiftUI

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard
            let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = NSString(
                data: data,
                encoding: String.Encoding.utf8.rawValue
            )
        else { return nil }

        return prettyPrintedString
    }
}

struct BlockchainView: View {
    @State var blocks = [Block]()
    @State var selectedBlock: Block?
    @State var remoteUrl: String = Endpoint.main

    var dateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.left")
                    .resizable()
                    .frame(width: 28, height: 24)
                    .padding(.top, 32)
                    Spacer()
                    Button(action: {
                        self.fetchAllBlocks()
                    }) {
                        Image(systemName: "arrow.2.circlepath")
                        .resizable()
                        .frame(width: 28, height: 24)
                        .padding(.top, 32)
                    }
                }
                
                Text("Blockchain URL")
                .padding(.top, 32)
                TextField("Remote", text: self.$remoteUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(Color.black)
                
                Text("Current Blockchain State")
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                    .padding(.top, 32)
                Text("\(blocks.count) Blocks")
                    .font(.system(size: 18))
                    .fontWeight(.light)
                    .foregroundColor(Color.white.opacity(0.75))
            }
            .padding(48)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    Spacer().frame(width: 34)
                    ForEach(blocks, id: \.id) { block in
                        HStack(alignment: .center, spacing: 0) {
                            Button(action: {
                                self.selectedBlock = block
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Block \(block.index)")
                                        .font(.headline)
                                    Text("Forged \(block.timestamp, formatter: self.dateFormatter)")
                                    Text("\(block.transactions.count) Transactions")
                                }
                                .foregroundColor(.black)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(radius: 12)
                            }

                            Rectangle().frame(width: 32, height: 2)
                        }
                    }
                }
            }
            .padding(.vertical, 24)

            if self.selectedBlock != nil {
                List(self.selectedBlock!.transactions) { transaction in
                    VStack {
                        Text("Sender: \(transaction.sender)")
                        Text("Receiver: \(transaction.receiver)")
                        Text("Data: \(transaction.data.prettyPrintedJSONString ?? "n/a")")
                    }
                }
                .foregroundColor(Color.black)
            }

            Spacer()
        }
        .foregroundColor(Color.white)
        .background(
            LinearGradient(
                gradient: Gradients.midnightCity,
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
        )
        .edgesIgnoringSafeArea(.vertical)
        .onAppear {
            self.fetchAllBlocks()
        }
    }
    
    func fetchAllBlocks() {
        let endpoint = URL(string: "\(self.remoteUrl)/blockchain/blocks/all")!
        var request = URLRequest(url: endpoint)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                error == nil,
                let data = data
            else {return }
            print(data.prettyPrintedJSONString)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            // swiftlint:disable all
            let blocks = try! decoder.decode([Block].self, from: data)
            
            self.blocks = blocks
        }
        task.resume()
    }
}

// swiftlint:disable:next type_name
struct BlockchainView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainView(blocks: [
            Block(
                index: 2,
                timestamp: Date().addingTimeInterval(-200),
                parentHash: [1, 2, 3],
                transactions: [
                    Transaction(
                        sender: "alice",
                        receiver: "bob",
                        data: "Hello Bob".data(using: .utf8)!,
                        timestamp: Date().addingTimeInterval(-250)
                    )
                ]
            ),
            Block(
                index: 1,
                timestamp: Date().addingTimeInterval(-15000),
                parentHash: [1, 2, 3],
                transactions: []
            ),
            Block(
                index: 0,
                timestamp: Date().addingTimeInterval(-300000),
                parentHash: [1, 2, 3],
                transactions: []
            )
        ])
    }
}
