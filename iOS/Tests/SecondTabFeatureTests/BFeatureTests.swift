import ComposableArchitecture
import Testing

@testable import SecondTabFeature

@MainActor
struct BFeatureTests {
    @Test
    func increment() async {
        let store = TestStore(initialState: BFeature.State()) {
            BFeature()
        }

        await store.send(.view(.incrementButtonTapped)) {
            $0.count = 1
        }
    }

    @Test
    func goToC() async {
        let store = TestStore(initialState: BFeature.State()) {
            BFeature()
        }

        await store.send(.view(.goToCButtonTapped)) {
            $0.destination = .c(CFeature.State())
        }
    }
}
