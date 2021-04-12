import SwiftUI

/// A reusable blur background, wrapping `UIBlurEffect`.
struct BlurView: UIViewRepresentable {
    private let style: UIBlurEffect.Style

    init(style: UIBlurEffect.Style = .systemMaterial) {
        self.style = style
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

/// A reusable card view with a subtle shadow.
private struct CardView<Content>: View where Content: View {
    private let blurEffect: UIBlurEffect.Style?
    private let content: Content

    /// Initialize the card view with an optional background blur effect.
    ///
    /// If `blurEffect` is `nil`, the view will use a regular white background.
    init(blurEffect: UIBlurEffect.Style? = nil, @ViewBuilder content: () -> Content) {
        self.blurEffect = blurEffect
        self.content = content()
    }

    private var background: some View {
        Group {
            if let blurEffect = blurEffect {
                BlurView(style: blurEffect)
            } else {
                Color.white
            }
        }
    }

    var body: some View {
        content
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}

private class NumbersOnly: ObservableObject {
    @Published var value: String {
        didSet {
            let filtered = value.filter { v in v.isNumber }
            if value != filtered {
                value = filtered
            }
        }
    }

    init(value: String) {
        self.value = value
    }
}

struct TransactionCreationView: View {
    let data: Data
    let receiver: String
    let onCreate: (Transaction) -> Void

    @EnvironmentObject var auth: AuthenticationEnvironment

    @Environment(\.presentationMode) var presentationMode

    @StateObject private var feeInput = NumbersOnly(value: "0")
    @State private var balanceInput = NumbersOnly(value: "0")
    @State var accountBalance: Int?

    enum TransactionCreationState {
        case loading // Load account balance and fee
        case inputValues // Input values
        case creating // Create transaction
        case succeeded // Transaction in chain
    }

    @State var state: TransactionCreationState = .loading

    func load() {
        guard accountBalance == nil else {
            state = .inputValues
            return
        }

        GetAccountBalanceRequest(account: auth.keyPair.publicKey).send { result in
            guard
                let response = try? result.get(),
                let balance = response.balance
            else { return }
            self.accountBalance = balance

            GetTransactionFeeRequest().send { result in
                guard
                    let response = try? result.get(),
                    let fee = response.fee
                else { return }
                DispatchQueue.main.async {
                    self.feeInput.value = "\(fee)"
                    state = .inputValues
                }
            }
        }
    }

    func createTransaction() {
        guard
            let fee = Int(feeInput.value),
            let balance = Int(balanceInput.value),
            let accountBalance = accountBalance,
            accountBalance >= (balance + fee)
        else { return }

        state = .creating

        var idData = Data(count: 32)
        let result = idData.withUnsafeMutableBytes {
            (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
        }

        guard result == errSecSuccess else { return }

        do {
            let encryptedData = try auth.keyPair.encrypt(data: data, partner: receiver)

            var transaction = Transaction(
                id: idData.hexString,
                sender: auth.keyPair.publicKey,
                receiver: receiver,
                balance: balance,
                timeUnixNano: Int(Date().timeIntervalSince1970 * 1_000_000_000),
                data: encryptedData,
                fee: fee,
                signature: nil
            )

            try auth.keyPair.sign(t: &transaction)

            CreateTransactionRequest(transaction: transaction).send { result in
                guard
                    let response = try? result.get(),
                    let transaction = response.transaction
                else { return }

                state = .succeeded
                DispatchQueue.main.async { onCreate(transaction) }
            }
        } catch { print(error) }
    }

    var inputCard: some View {
        CardView {
            VStack(alignment: .leading) {
                Group {
                Text("New Transaction").font(.title)
                Text("Current account balance: \(accountBalance ?? 0)")
                Divider().padding(.vertical)
                Text("Transaction Fee (Recommended Minimum)")
                TextField("", text: $feeInput.value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Divider().padding(.vertical)
                Text("Transfer Balance")
                TextField("", text: $balanceInput.value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Divider().padding(.vertical)
                }
                Button(action: createTransaction) {
                    HStack {
                        Spacer()
                        Text("Send Transaction")
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    var overlay: some View {
        Group {
            switch state {
            case .loading:
                ZStack {
                    BlurView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    VStack {
                        Text("Loading...")
                        ProgressView()
                    }
                }
            case .creating:
                ZStack {
                    BlurView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    VStack {
                        Text("Creating transaction...")
                        ProgressView()
                    }
                }
            case .inputValues:
                EmptyView()
            case .succeeded:
                ZStack {
                    BlurView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(12)
                    VStack {
                        Text("Transaction created!")
                    }
                }
            }
        }
    }
    
    var body: some View {
        inputCard
            .overlay(overlay)
        .padding()
        .onAppear(perform: load)
    }
}

struct TransactionCreationView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCreationView(
            data: Data(),
            receiver: "0372689db204d56d9bb7122497eef4732cce308b73f3923fc076aed3c2dfa4ad04"
        ){_ in}.environmentObject(AuthenticationEnvironment(keyPair: .init(
            pub: "0372689db204d56d9bb7122497eef4732cce308b73f3923fc076aed3c2dfa4ad04",
            priv: "eba4f82788edb8e464920293ff06605484bef87561880e44b6e4902f27e6d6ca"
        )))
    }
}
