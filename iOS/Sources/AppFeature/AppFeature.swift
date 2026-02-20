import ComposableArchitecture
import CounterFeature
import SecondTabFeature
import SwiftUI

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

        Reduce { _, _ in .none }
    }
}

public struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack {
                CounterView(
                    store: store.scope(state: \.counter, action: \.counter)
                )
            }
            .tabItem {
                Label("Counter", systemImage: "plusminus.circle")
            }
            .tag(AppFeature.State.Tab.counter)

            SecondTabView(
                store: store.scope(state: \.secondTab, action: \.secondTab)
            )
            .tabItem {
                Label("Navigate", systemImage: "arrow.right.square")
            }
            .tag(AppFeature.State.Tab.navigate)
        }
    }
}

public struct AppRootView: View {
    public init() {}

    public var body: some View {
        AppView(
            store: Store(initialState: AppFeature.State()) {
                AppFeature()
            }
        )
    }
}
