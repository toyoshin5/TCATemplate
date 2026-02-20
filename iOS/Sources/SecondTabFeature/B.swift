import ComposableArchitecture
import SwiftUI

@Reducer
public struct BFeature {
    @Reducer
    public enum Destination {
        case c(CFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public var count = 0
        @Presents public var destination: Destination.State?

        public init() {}
    }

    public enum Action: Equatable {
        case view(ViewAction)
        case destination(PresentationAction<Destination.Action>)

        public enum ViewAction: Equatable {
            case incrementButtonTapped
            case goToCButtonTapped
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.incrementButtonTapped):
                state.count += 1
                return .none

            case .view(.goToCButtonTapped):
                state.destination = .c(CFeature.State())
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension BFeature.Destination.Action: Equatable {}
extension BFeature.Destination.State: Equatable {}

public struct BView: View {
    @Bindable var store: StoreOf<BFeature>

    public init(store: StoreOf<BFeature>) {
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

            Button("Go to C") {
                store.send(.view(.goToCButtonTapped))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("B")
    }
}
