import Foundation
import Harmonize
import HarmonizeSemantics

/// SwiftUI View層に関するルール群。
///
/// アサート対象はトップレベルのView struct。baselineにはView名(例: `"PostView"`)を書く。
public enum ViewRules {
    /// R5a: Viewは `@Dependency` を直接使わない(依存はReducer経由で解決する)。
    public static func viewsDoNotUseDependencies(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "view-no-dependency",
            rationale: "Viewが@Dependencyを持つとテストでのoverrideが効かず、副作用がReducerの外に漏れる。依存はFeatureに置きStore経由で渡す。"
        )
        // storedプロパティだけでなくメソッド内のローカル@Dependencyも捕捉するため宣言全文を見る
        topLevelViewStructs(in: scope).assertFalse(
            message: rule.rationale,
            rule: rule,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { view in
            view.description.contains("@Dependency")
        }
    }

    /// R5b: `Store(initialState:)` の生成はcomposition rootと `#Preview` のみ。
    ///
    /// View本体(convenience initや`@State`プロパティ)でのStore生成は、親Reducerから
    /// 切り離された独立ツリーを作ってしまう(親のテストに写らない・dependency overrideが効かない)。
    public static func storesAreCreatedOnlyInCompositionRoot(
        in scope: HarmonizeScope,
        config: TCAArchConfig,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "store-creation-composition-root",
            rationale: "Store生成はcomposition rootと#Previewに限定する。Viewが生成したStoreは親から切り離された孤立ツリーになる。"
        )
        // #Previewブロックはトップレベルマクロなのでstruct宣言の外にあり、この検査には掛からない。
        topLevelViewStructs(in: scope)
            .filter { !config.storeCreationAllowedTypes.contains($0.name) }
            .assertFalse(
                message: rule.rationale,
                rule: rule,
                baseline: baseline,
                fileID: fileID, file: file, line: line, column: column
            ) { view in
                view.description.contains("Store(initialState:")
            }
    }

    /// R5c: StoreOfを保持するViewのstoredプロパティ名は `store` に統一する。
    public static func storePropertiesAreNamedStore(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "store-property-naming",
            rationale: "ViewのStoreOfプロパティは`store`という名前1つに統一する。複数Storeを持ちたくなったら設計を見直すサイン。"
        )
        topLevelViewStructs(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { view in
            let storeVariables = view.variables.filter {
                $0.typeAnnotation?.annotation.contains("StoreOf<") == true && $0.isStored
            }
            return storeVariables.allSatisfy { $0.name == "store" }
        }
    }

    /// R5d: `view(View)` グループを持つFeatureに対応するViewは `@ViewAction(for:)` を付ける。
    ///
    /// 対応関係は `StoreOf<XxxFeature>` プロパティの型から判定する。
    public static func viewsUseViewActionMacro(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        // ViewActionプロトコルに準拠したActionを持つReducer名を収集
        let viewActionReducers = Set(
            topLevelReducerStructs(in: scope)
                .filter { reducer in
                    reducer.enums.first { $0.name == "Action" }?.conforms(to: "ViewAction") == true
                }
                .map(\.name)
        )
        let rule = Rule(
            id: "view-action-macro",
            rationale: "view(View)グループを持つFeatureのViewは@ViewAction(for:)を付け、send(.tapped)で直接view actionを送る。"
        )
        topLevelViewStructs(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { view in
            // このViewが保持するStoreOf<XxxFeature>のFeature名を取り出す
            let heldReducers = view.variables.compactMap { variable -> String? in
                guard let type = variable.typeAnnotation?.annotation,
                      let range = type.range(of: #"StoreOf<([A-Za-z0-9_]+)>"#, options: .regularExpression)
                else { return nil }
                return String(type[range].dropFirst("StoreOf<".count).dropLast(1))
            }
            let needsViewAction = heldReducers.contains { viewActionReducers.contains($0) }
            guard needsViewAction else { return true }
            return view.hasAttribute("ViewAction")
        }
    }
}
