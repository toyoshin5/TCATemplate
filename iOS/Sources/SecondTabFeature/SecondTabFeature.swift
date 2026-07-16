import ComposableArchitecture

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

    public enum Action: ViewAction {
        case view(View)
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        public enum View {
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

// @Reducer enumが生成するStateはEquatableを自動導出しないため明示的に付与する
extension SecondTabFeature.Destination.State: Equatable {}
