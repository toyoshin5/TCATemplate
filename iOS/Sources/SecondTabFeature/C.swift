import ComposableArchitecture
import SwiftUI

@Reducer
public struct CFeature {
    @Reducer
    public enum Destination {
        case d(DFeature)
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
            case goToDButtonTapped
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.incrementButtonTapped):
                state.count += 1
                return .none

            case .view(.goToDButtonTapped):
                state.destination = .d(DFeature.State())
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension CFeature.Destination.Action: Equatable {}
extension CFeature.Destination.State: Equatable {}

public struct CView: View {
    @Bindable var store: StoreOf<CFeature>

    public init(store: StoreOf<CFeature>) {
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

            Button("Go to D") {
                store.send(.view(.goToDButtonTapped))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("C")
    }
}
