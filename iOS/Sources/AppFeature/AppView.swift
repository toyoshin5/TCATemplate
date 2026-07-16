import ComposableArchitecture
import CounterFeature
import SecondTabFeature
import SwiftUI

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
