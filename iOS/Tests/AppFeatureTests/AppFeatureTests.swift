import ComposableArchitecture
import CounterFeature
import Testing

@testable import AppFeature

@MainActor
struct AppFeatureTests {
    @Test
    func tabSelection() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(\.binding.selectedTab, .navigate) {
            $0.selectedTab = .navigate
        }
    }

    @Test
    func childCounterIncrements() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(\.counter.view.incrementButtonTapped) {
            $0.counter.count = 1
        }
    }
}
