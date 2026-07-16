import ComposableArchitecture
import SwiftUI

@ViewAction(for: BFeature.self)
public struct BView: View {
    @Bindable public var store: StoreOf<BFeature>

    public init(store: StoreOf<BFeature>) {
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

            Button("Go to C") {
                send(.goToCButtonTapped)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("B")
        .navigationDestination(
            item: $store.scope(state: \.destination?.c, action: \.destination.c)
        ) { cStore in
            CView(store: cStore)
        }
    }
}
