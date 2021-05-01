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
            ScrollViewReader { scrollViewReader in
                LazyVStack {
                    ForEach(0 ..< transactions.endIndex, id: \.self) { i in
                        MessageRowView(
                            transaction: transactions[i],
                            previous: transactions[optional: i - 1],
                            next: transactions[optional: i + 1]
                        )
                        .tag(i)
                    }
                }
                .onChange(of: transactions, perform: { value in
                    scrollViewReader.scrollTo(transactions.endIndex - 1, anchor: .bottom)
                })
                .padding(.vertical)
            }
        }
    }
}
