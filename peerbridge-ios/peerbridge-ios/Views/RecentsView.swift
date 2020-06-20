import SwiftUI
import SwiftyRSA
import Foundation

struct Recent {
    let publicKey: String
    let message: String
    let date: Date
}

struct RecentsView: View {
    @State var recents = [Recent]()
    @State var transactionsByPartnerPublicKey = Dictionary<String, [Transaction]>()
    
    @State var isShowingSheet = false
    @State var messages = [Message]()
    @State var selectedPublicKey: String?
    
    var body: some View {
        NavigationView {
            Color(hex: "#3867d6")
            .edgesIgnoringSafeArea(.top)
            .overlay(VStack {
                top
                ZStack(alignment: .bottom) {
                    center
                    navBar
                }
            })
        }
        .sheet(isPresented: self.$isShowingSheet) {
            ChatView(messages: self.$messages, receiverPublicKeyString: self.$selectedPublicKey)
        }
    }
    
    var top: some View {
        HStack {
            Text("Recents")
            .fontWeight(.heavy)
            .font(.system(size: 24))
            
            Spacer()
            
            Button(action: self.loadRecents) {
                Image(systemName: "arrow.2.circlepath")
                .frame(width: 32, height: 32)
                .background(Color(hex: "#4b7bec"))
                .cornerRadius(16)
            }
        }
        .padding(24)
        .background(Color(hex: "#3867d6"))
        .foregroundColor(Color(hex: "#d1d8e0"))
    }
    
    var center: some View {
        ScrollView {
            HStack {
                Spacer()
                VStack(spacing: 24) {
                    ForEach(self.recents, id: \.publicKey) { recent in
                        Button(action: {
                            guard
                                let keyPairData = Keychain.load(dataBehindKey: "keyPair"),
                                let keyPair = try? ISO8601Decoder().decode(RSAKeyPair.self, from: keyPairData)
                            else { return }
                            
                            self.selectedPublicKey = recent.publicKey
                            self.messages = self
                                .transactionsByPartnerPublicKey[recent.publicKey]!
                                .compactMap {$0.decryptMessage(withKeyPair: keyPair)}
                            self.isShowingSheet = true
                        }) {
                            HStack(alignment: .center) {
                                Circle()
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(Color.gray.opacity(0.2))
                                
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading) {
                                        Text("\(recent.publicKey)")
                                        .fontWeight(.semibold)
                                        .font(.system(size: 16))
                                        .lineLimit(1)
                                        Text("\(recent.message)")
                                        .fontWeight(.regular)
                                        .foregroundColor(Color.black.opacity(0.6))
                                        .font(.system(size: 12))
                                        .padding(.top, 4)
                                        .lineLimit(3)
                                    }
                                    Spacer()
                                    Text("\(recent.date, formatter: RelativeDateTimeFormatter())")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.black.opacity(0.6))
                                    .padding(.top, 4)
                                    .lineLimit(1)
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                Spacer()
            }
        }
        .background(Color.white)
    }
    
    var navBar: some View {
        HStack {
            Spacer()
            NavigationLink(destination: StartChatView()) {
                Image(systemName: "plus")
                .frame(width: 64, height: 64)
                .background(Color(hex: "#4b7bec"))
                .cornerRadius(32)
            }
            Spacer()
        }
        .foregroundColor(Color(hex: "#d1d8e0"))
    }
    
    func loadRecents() {
        guard
            let keyPairData = Keychain.load(dataBehindKey: "keyPair"),
            let keyPair = try? ISO8601Decoder().decode(RSAKeyPair.self, from: keyPairData),
            let ownPublicKeyString = try? keyPair.publicKey.pemString()
        else { return }
        
        Transaction.loadAll(byPublicKey: ownPublicKeyString) { transactions in
            guard let transactions = transactions else { return }
            
            self.transactionsByPartnerPublicKey = Dictionary<String, [Transaction]>(
                grouping: transactions, by: { transaction in
                    if transaction.receiver == ownPublicKeyString {
                        return transaction.sender
                    }
                    return transaction.receiver
                }
            )
            
            self.recents = self.transactionsByPartnerPublicKey
                .compactMap { (partnerPublicKey, transactions) in
                    guard
                        let mostRecentTransaction = transactions
                            .max(by: { (a, b) -> Bool in return a.timestamp < b.timestamp }),
                        let message = mostRecentTransaction.decryptMessage(withKeyPair: keyPair)
                    else {return nil}
                    return Recent(
                        publicKey: partnerPublicKey,
                        message: message.content,
                        date: message.date
                    )
                }
        }
    }
}

struct RecentsView_Previews: PreviewProvider {
    static var previews: some View {
        RecentsView(
            recents: [
                .init(publicKey: "Public Key 1", message: "Hello", date: Date()),
                .init(publicKey: "Public Key 2", message: "Hello", date: Date()),
                .init(publicKey: "Public Key 3", message: "Hello", date: Date())
            ]
        )
    }
}
