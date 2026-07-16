import ComposableArchitecture
import NumberFactClient

@Reducer
public struct CounterFeature {
    @ObservableState
    public struct State: Equatable {
        public var count = 0
        public var fact: String?
        public var isLoadingFact = false

        public init() {}
    }

    public enum Action: ViewAction {
        case view(View)
        case `internal`(Internal)

        @CasePathable
        public enum View {
            case decrementButtonTapped
            case incrementButtonTapped
            case factButtonTapped
        }

        @CasePathable
        public enum Internal {
            case factResponse(Result<String, any Error>)
        }
    }

    @Dependency(\.numberFactClient) var numberFactClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .view(.decrementButtonTapped):
                state.count -= 1
                state.fact = nil
                return .none

            case .view(.incrementButtonTapped):
                state.count += 1
                state.fact = nil
                return .none

            case .view(.factButtonTapped):
                state.isLoadingFact = true
                state.fact = nil
                return .run { [count = state.count, numberFactClient] send in
                    await send(
                        .internal(.factResponse(Result { try await numberFactClient.fact(count) }))
                    )
                }

            case let .internal(.factResponse(.success(fact))):
                state.isLoadingFact = false
                state.fact = fact
                return .none

            case .internal(.factResponse(.failure)):
                state.isLoadingFact = false
                return .none
            }
        }
    }
}
