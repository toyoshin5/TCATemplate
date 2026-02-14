import ComposableArchitecture
@testable import CounterFeature
import XCTest

final class CounterFeatureTests: XCTestCase {
  @MainActor
  func testIncrementAndDecrement() async {
    let store = TestStore(initialState: CounterFeature.State()) {
      CounterFeature()
    }

    await store.send(.incrementButtonTapped) {
      $0.count = 1
    }

    await store.send(.incrementButtonTapped) {
      $0.count = 2
    }

    await store.send(.decrementButtonTapped) {
      $0.count = 1
    }
  }
}
