import ComposableArchitecture
import SwiftUI

@ViewAction(for: CFeature.self)
public struct CView: View {
    @Bindable public var store: StoreOf<CFeature>

    public init(store: StoreOf<CFeature>) {
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

            Button("Go to D") {
                send(.goToDButtonTapped)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("C")
        .navigationDestination(
            item: $store.scope(state: \.destination?.d, action: \.destination.d)
        ) { dStore in
            DView(store: dStore)
        }
    }
}
