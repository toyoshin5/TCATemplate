import ComposableArchitecture
import SwiftUI

/// composition root。`Store(initialState:)` の生成はここ(と`#Preview`)だけに許可される
/// (アーキテクチャルール R5b: store-creation-composition-root)。
public struct AppRootView: View {
    public init() {}

    public var body: some View {
        AppView(
            store: Store(initialState: AppFeature.State()) {
                AppFeature()
            }
        )
    }
}
