import ComposableArchitecture
import SwiftUI

@Reducer
public struct CFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {
    case goToDButtonTapped
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

public struct CView: View {
  let store: StoreOf<CFeature>

  public init(store: StoreOf<CFeature>) {
    self.store = store
  }

  public var body: some View {
    Button("Go to D") {
      store.send(.goToDButtonTapped)
    }
    .buttonStyle(.borderedProminent)
    .navigationTitle("C")
  }
}
