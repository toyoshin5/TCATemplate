import ComposableArchitecture
import SwiftUI

@Reducer
public struct DFeature {
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {
    case noop
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}

public struct DView: View {
  let store: StoreOf<DFeature>

  public init(store: StoreOf<DFeature>) {
    self.store = store
  }

  public var body: some View {
    Text("D Screen")
      .navigationTitle("D")
  }
}
