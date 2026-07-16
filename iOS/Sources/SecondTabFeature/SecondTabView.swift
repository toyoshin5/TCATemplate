import ComposableArchitecture
import SwiftUI

@ViewAction(for: SecondTabFeature.self)
public struct SecondTabView: View {
    @Bindable public var store: StoreOf<SecondTabFeature>

    public init(store: StoreOf<SecondTabFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Second Tab")
                    .font(.title2.weight(.semibold))

                Text("Count: \(store.count)")
                    .monospacedDigit()

                Button("+1") {
                    send(.incrementButtonTapped)
                }
                .buttonStyle(.bordered)

                Button {
                    send(.goToBButtonTapped)
                } label: {
                    Label("Go to B", systemImage: "arrow.right.circle.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle("Navigate")
            .navigationDestination(
                item: $store.scope(state: \.destination?.b, action: \.destination.b)
            ) { bStore in
                BView(store: bStore)
            }
        }
    }
}
