
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
    @State private var decryptedMessage: Message? = nil
    
    private func decryptMessage() {
        guard
            let decryptedMessage = try? transaction
                .decrypt(withKeyPair: auth.keyPair)
        else { return }
        self.decryptedMessage = decryptedMessage
    }
    
    private var isOwnMessage: Bool {
        transaction.sender == auth.keyPair.publicKey.pemString
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
                Color.white
            }
        }
    }
    
    public var body: some View {
        HStack {
            if isOwnMessage {
                Spacer()
            }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading) {
                HStack {
                    Text(transaction.timestamp, style: .relative)
                        .font(.caption2)
                    Image(systemName: "lock")
                        .resizable()
                        .frame(width: 8, height: 10)
                }
                .padding(.bottom, 2)
                Text(decryptedMessage?.content ?? "Encrypted Message")
                    .lineLimit(nil)
            }
            .padding()
            .foregroundColor(
                isOwnMessage ? Color.white : Color.black
            )
            .background(background)
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


#if DEBUG
struct MessageRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MessageRowView(
                transaction: .example1,
                previous: nil,
                next: .example2
            ).environmentObject(AuthenticationEnvironment.bob)
            MessageRowView(
                transaction: .example2,
                previous: .example1,
                next: nil
            ).environmentObject(AuthenticationEnvironment.bob)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.04))
    }
}
#endif
