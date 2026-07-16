import ComposableArchitecture
import Testing

@testable import SecondTabFeature

@MainActor
struct SecondTabFeatureTests {
    @Test
    func increment() async {
        let store = TestStore(initialState: SecondTabFeature.State()) {
            SecondTabFeature()
        }

        await store.send(.view(.incrementButtonTapped)) {
            $0.count = 1
        }
    }

    @Test
    func goToB() async {
        let store = TestStore(initialState: SecondTabFeature.State()) {
            SecondTabFeature()
        }

        await store.send(.view(.goToBButtonTapped)) {
            $0.destination = .b(BFeature.State())
        }
    }
}
