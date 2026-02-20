import ComposableArchitecture
import SwiftUI

@Reducer
public struct SecondTabFeature {
    @Reducer
    public enum Destination {
        case b(BFeature)
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
            case goToBButtonTapped
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.incrementButtonTapped):
                state.count += 1
                return .none

            case .view(.goToBButtonTapped):
                state.destination = .b(BFeature.State())
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension SecondTabFeature.Destination.Action: Equatable {}
extension SecondTabFeature.Destination.State: Equatable {}

public struct SecondTabView: View {
    @Bindable var store: StoreOf<SecondTabFeature>

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
                    store.send(.view(.incrementButtonTapped))
                }
                .buttonStyle(.bordered)

                Button {
                    store.send(.view(.goToBButtonTapped))
                } label: {
                    Label("Go to B", systemImage: "arrow.right.circle.fill")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .navigationTitle("Navigate")
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.b, action: \.destination.b)
        ) { rawBStore in
            @Bindable var bStore = rawBStore
            BView(store: bStore)
                .navigationDestination(
                    item: $bStore.scope(state: \.destination?.c, action: \.destination.c)
                ) { rawCStore in
                    @Bindable var cStore = rawCStore
                    CView(store: cStore)
                        .navigationDestination(
                            item: $cStore.scope(state: \.destination?.d, action: \.destination.d)
                        ) { dStore in
                            DView(store: dStore)
                        }
                }
        }
    }
}
