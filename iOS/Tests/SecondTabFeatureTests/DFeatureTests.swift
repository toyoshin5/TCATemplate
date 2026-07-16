import ComposableArchitecture
import Testing

@testable import SecondTabFeature

@MainActor
struct DFeatureTests {
    @Test
    func increment() async {
        let store = TestStore(initialState: DFeature.State()) {
            DFeature()
        }

        await store.send(.view(.incrementButtonTapped)) {
            $0.count = 1
        }
    }
}
