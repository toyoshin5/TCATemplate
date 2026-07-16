import ComposableArchitecture

@Reducer
public struct DFeature {
    @ObservableState
    public struct State: Equatable {
        public var count = 0

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)

        @CasePathable
        public enum View {
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
