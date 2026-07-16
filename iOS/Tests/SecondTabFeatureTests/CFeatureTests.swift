import ComposableArchitecture
import Testing

@testable import SecondTabFeature

@MainActor
struct CFeatureTests {
    @Test
    func increment() async {
        let store = TestStore(initialState: CFeature.State()) {
            CFeature()
        }

        await store.send(.view(.incrementButtonTapped)) {
            $0.count = 1
        }
    }

    @Test
    func goToD() async {
        let store = TestStore(initialState: CFeature.State()) {
            CFeature()
        }

        await store.send(.view(.goToDButtonTapped)) {
            $0.destination = .d(DFeature.State())
        }
    }
}
