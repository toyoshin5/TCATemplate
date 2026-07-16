import ComposableArchitecture
import SwiftUI

@ViewAction(for: CounterFeature.self)
public struct CounterView: View {
    public let store: StoreOf<CounterFeature>

    public init(store: StoreOf<CounterFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("\(store.count)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button("-") {
                    send(.decrementButtonTapped)
                }
                .buttonStyle(.bordered)

                Button("+") {
                    send(.incrementButtonTapped)
                }
                .buttonStyle(.borderedProminent)
            }

            Button("What is this number?") {
                send(.factButtonTapped)
            }
            .buttonStyle(.bordered)

            if store.isLoadingFact {
                ProgressView()
            } else if let fact = store.fact {
                Text(fact)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Counter")
    }
}
