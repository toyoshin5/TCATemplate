import ComposableArchitecture
import SwiftUI

@ViewAction(for: DFeature.self)
public struct DView: View {
    public let store: StoreOf<DFeature>

    public init(store: StoreOf<DFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(store.count)")
                .monospacedDigit()

            Button("+1") {
                send(.incrementButtonTapped)
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("D")
    }
}
