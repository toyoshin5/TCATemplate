import ComposableArchitecture
import NumberFactClient
import Testing

@testable import CounterFeature

@MainActor
struct CounterFeatureTests {
    @Test
    func incrementAndDecrement() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }

        await store.send(.view(.incrementButtonTapped)) {
            $0.count = 1
        }

        await store.send(.view(.incrementButtonTapped)) {
            $0.count = 2
        }

        await store.send(.view(.decrementButtonTapped)) {
            $0.count = 1
        }
    }

    @Test
    func numberFact() async {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        } withDependencies: {
            $0.numberFactClient.fact = { "\($0) is a great number." }
        }

        await store.send(.view(.incrementButtonTapped)) {
            $0.count = 1
        }

        await store.send(.view(.factButtonTapped)) {
            $0.isLoadingFact = true
        }

        await store.receive(\.internal.factResponse.success) {
            $0.isLoadingFact = false
            $0.fact = "1 is a great number."
        }
    }
}
