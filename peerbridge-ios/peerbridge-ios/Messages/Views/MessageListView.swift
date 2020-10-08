import SwiftUI

fileprivate extension Collection {
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
}


struct MessageListView: View {
    @Binding var transactions: [Transaction]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(0 ..< transactions.count, id: \.self) { i in
                    MessageRowView(
                        transaction: transactions[i],
                        previous: transactions[optional: i - 1],
                        next: transactions[optional: i + 1]
                    )
                }
            }
            .padding(.vertical)
        }
    }
}


struct MessageListView_Previews: PreviewProvider {
    static var previews: some View {
        MessageListView(transactions: .constant([
            .example1, .example1, .example1, .example2
        ]))
            .environmentObject(AuthenticationEnvironment.alice)
    }
}
