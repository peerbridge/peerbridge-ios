
import SwiftUI

fileprivate struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


fileprivate extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}


public struct MessageRowView: View {
    public let transaction: Transaction
    public let previous: Transaction?
    public let next: Transaction?
    
    @EnvironmentObject private var auth: AuthenticationEnvironment
    @State private var messageDescription: String? = nil
    
    func decryptMessage() {
        guard let data = transaction.data else {
            if transaction.balance > 0 {
                messageDescription = "Cryptocurrency Transfer"
            } else {
                messageDescription = "Empty Message"
            }
            return
        }

        guard let decryptedData = try? auth.keyPair.decrypt(
            data: data, partner: transaction.sender == auth.keyPair.publicKey ?
                transaction.receiver : transaction.sender
        ) else {
            messageDescription = "Encrypted message"
            return
        }
        
        guard let message = MessageDecoder().decode(from: decryptedData) else {
            messageDescription = "Unknown Message"
            return
        }
        
        messageDescription = message.shortDescription
    }
    
    private var isOwnMessage: Bool {
        transaction.sender == auth.keyPair.publicKey
    }
    
    private var followsMessageGroup: Bool {
        guard
            let previous = previous,
            previous.sender == transaction.sender
        else { return false }
        return true
    }
    
    private var isFollowedByMessageGroup: Bool {
        guard
            let next = next,
            next.sender == transaction.sender
        else { return false }
        return true
    }
    
    private var roundedCorners: UIRectCorner {
        if isOwnMessage {
            if followsMessageGroup && isFollowedByMessageGroup {
                return [.topLeft, .bottomLeft]
            } else if followsMessageGroup {
                return [.topLeft, .bottomLeft, .bottomRight]
            } else if isFollowedByMessageGroup {
                return [.topLeft, .bottomLeft, .topRight]
            }
            return [.allCorners]
        } else {
            if followsMessageGroup && isFollowedByMessageGroup {
                return [.topRight, .bottomRight]
            } else if followsMessageGroup {
                return [.topRight, .bottomRight, .bottomLeft]
            } else if isFollowedByMessageGroup {
                return [.topRight, .bottomRight, .topLeft]
            }
            return [.allCorners]
        }
    }
        
    private var background: some View {
        Group {
            if isOwnMessage {
                LinearGradient(
                    gradient: Styles.blueGradient,
                    startPoint: .topLeading,
                    endPoint: .topTrailing
                )
            } else {
                Color("Background")
            }
        }
    }

    private var url: URL {
        URL(string: "\(Endpoints.main)/dashboard/transaction?id=\(transaction.id)")!
    }
    
    public var body: some View {
        Link(destination: url) {
            HStack {
                if isOwnMessage {
                    Spacer()
                }

                VStack(alignment: isOwnMessage ? .trailing : .leading) {
                    HStack {
                        if isOwnMessage {
                            Spacer()
                        }
                        Text(transaction.time, style: .relative)
                            .font(.caption2)
                        Image(systemName: "lock")
                            .resizable()
                            .frame(width: 8, height: 10)
                        if !isOwnMessage {
                            Spacer()
                        }
                    }
                    .frame(width: 128)
                    .padding(.bottom, 2)
                    if let description = messageDescription {
                        Text(description)
                            .lineLimit(nil)
                    }
                    if transaction.balance > 0 {
                        Text("Sent \(transaction.balance) 🪙")
                            .padding(.top, 2)
                    }
                }
                .padding()
                .background(background)
                .foregroundColor(isOwnMessage ? Color.white : Color("Foreground"))
                .cornerRadius(12, corners: roundedCorners)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 12, x: 0, y: 4
                )
                .padding(.horizontal)

                if !isOwnMessage {
                    Spacer()
                }
            }
            .onAppear(perform: decryptMessage)
        }
    }
}
