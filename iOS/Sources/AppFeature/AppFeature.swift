import ComposableArchitecture
import CounterFeature
import SecondTabFeature

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Tab: String, Equatable {
            case counter
            case navigate
        }

        public var selectedTab: Tab = .counter
        public var counter = CounterFeature.State()
        public var secondTab = SecondTabFeature.State()

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case counter(CounterFeature.Action)
        case secondTab(SecondTabFeature.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.counter, action: \.counter) {
            CounterFeature()
        }

        Scope(state: \.secondTab, action: \.secondTab) {
            SecondTabFeature()
        }
    }
}
