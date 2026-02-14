import ComposableArchitecture
import SwiftUI

@Reducer
public struct BFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {
    case goToCButtonTapped
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

public struct BView: View {
  let store: StoreOf<BFeature>

  public init(store: StoreOf<BFeature>) {
    self.store = store
  }

  public var body: some View {
    Button("Go to C") {
      store.send(.goToCButtonTapped)
    }
    .buttonStyle(.borderedProminent)
    .navigationTitle("B")
  }
}
