import ComposableArchitecture
import SwiftUI

@Reducer
public struct DFeature {
    @ObservableState
    public struct State: Equatable {
        public var count = 0

        public init() {}
    }

    public enum Action: Equatable {
        case view(ViewAction)

        public enum ViewAction: Equatable {
            case incrementButtonTapped
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.incrementButtonTapped):
                state.count += 1
                return .none
            }
        }
    }
}

public struct DView: View {
    let store: StoreOf<DFeature>

    public init(store: StoreOf<DFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(store.count)")
                .monospacedDigit()

            Button("+1") {
                store.send(.view(.incrementButtonTapped))
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("D")
    }
}
