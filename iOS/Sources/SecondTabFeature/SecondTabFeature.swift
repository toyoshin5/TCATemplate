import ComposableArchitecture
import SwiftUI

@Reducer
public struct DetailFeature {
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

public struct DetailView: View {
  let store: StoreOf<DetailFeature>

  public init(store: StoreOf<DetailFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "sparkles")
        .font(.largeTitle)
      Text("Detail Screen")
        .font(.title3.weight(.semibold))
      Text("2つ目タブから1回だけ遷移する最小構成です。")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .navigationTitle("Detail")
  }
}

@Reducer
public struct SecondTabFeature {
  @ObservableState
  public struct State: Equatable {
    public var isDetailActive = false
    public var detail = DetailFeature.State()

    public init() {}
  }

  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case detail(DetailFeature.Action)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.detail, action: \.detail) {
      DetailFeature()
    }
    Reduce { _, _ in .none }
  }
}

public struct SecondTabView: View {
  @Bindable var store: StoreOf<SecondTabFeature>

  public init(store: StoreOf<SecondTabFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        Text("Second Tab")
          .font(.title2.weight(.semibold))

        Button {
          store.isDetailActive = true
        } label: {
          Label("Go to Detail", systemImage: "arrow.right.circle.fill")
            .font(.body.weight(.semibold))
        }
        .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding()
      .navigationTitle("Navigate")
      .navigationDestination(isPresented: $store.isDetailActive) {
        DetailView(store: store.scope(state: \.detail, action: \.detail))
      }
    }
  }
}
