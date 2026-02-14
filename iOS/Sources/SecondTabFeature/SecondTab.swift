import ComposableArchitecture
import SwiftUI

@Reducer
public struct SecondTabFeature {
  @Reducer
  public enum Path {
    case b(BFeature)
    case c(CFeature)
    case d(DFeature)
  }

  @ObservableState
  public struct State: Equatable {
    public var path = StackState<Path.State>()

    public init() {}
  }

  public enum Action: Equatable {
    case goToBButtonTapped
    case path(StackAction<Path.State, Path.Action>)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .goToBButtonTapped:
        state.path.append(.b(BFeature.State()))
        return .none

      case .path(.element(id: _, action: .b(.goToCButtonTapped))):
        state.path.append(.c(CFeature.State()))
        return .none

      case .path(.element(id: _, action: .c(.goToDButtonTapped))):
        state.path.append(.d(DFeature.State()))
        return .none

      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension SecondTabFeature.Path.State: Equatable {}
extension SecondTabFeature.Path.Action: Equatable {}

public struct SecondTabView: View {
  @Bindable var store: StoreOf<SecondTabFeature>

  public init(store: StoreOf<SecondTabFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      VStack(spacing: 16) {
        Text("Second Tab")
          .font(.title2.weight(.semibold))

        Button {
          store.send(.goToBButtonTapped)
        } label: {
          Label("Go to B", systemImage: "arrow.right.circle.fill")
            .font(.body.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
      .navigationTitle("Navigate")
    } destination: { store in
      switch store.case {
      case let .b(store):
        BView(store: store)
      case let .c(store):
        CView(store: store)
      case let .d(store):
        DView(store: store)
      }
    }
  }
}
