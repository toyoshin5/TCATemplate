import ComposableArchitecture
import SwiftUI

@Reducer
public struct CounterFeature {
  @ObservableState
  public struct State: Equatable {
    public var count = 0

    public init() {}
  }

  public enum Action: Equatable {
    case decrementButtonTapped
    case incrementButtonTapped
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        return .none
      case .incrementButtonTapped:
        state.count += 1
        return .none
      }
    }
  }
}

public struct CounterView: View {
  let store: StoreOf<CounterFeature>

  public init(store: StoreOf<CounterFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 16) {
      Text("\(store.count)")
        .font(.system(size: 56, weight: .bold, design: .rounded))
        .monospacedDigit()

      HStack(spacing: 12) {
        Button("-1") {
          store.send(.decrementButtonTapped)
        }
        .buttonStyle(.bordered)

        Button("+1") {
          store.send(.incrementButtonTapped)
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .navigationTitle("Counter")
  }
}
