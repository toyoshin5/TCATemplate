import Foundation
import Harmonize
import HarmonizeSemantics

/// Reducer(`@Reducer`)に関するルール群。
///
/// アサート対象は常にトップレベルのReducer宣言なので、baselineにはReducer名
/// (例: `"PostingFeature"`)をそのまま書ける。
public enum ReducerRules {
    /// R1a: `@Reducer` 型は `*Feature` 命名にする。
    ///
    /// nestedな `@Reducer enum Destination/Path` は対象外(トップレベルのみ検査)。
    public static func reducersAreSuffixedFeature(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "reducer-naming-feature-suffix",
            rationale: "Reducerは<Domain>Feature命名に統一する。Viewとの対応(PostingFeature ↔ PostingView)とドメイン型との衝突回避のため。"
        )
        let reducerStructs = topLevelReducerStructs(in: scope)
        let reducerEnums = topLevelReducerEnums(in: scope)

        reducerStructs.assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: reducerStructs.relevantBaseline(baseline),
            fileID: fileID, file: file, line: line, column: column
        ) { $0.name.hasSuffix("Feature") }

        reducerEnums.assertTrue(
            message: "トップレベルの@Reducer enumも*Feature命名にする(Destination/Pathはnestedに置く)。",
            rule: rule,
            baseline: reducerEnums.relevantBaseline(baseline),
            fileID: fileID, file: file, line: line, column: column
        ) { $0.name.hasSuffix("Feature") }
    }

    /// R1b: Reducerは `featureDirs`(または `appDirs`)配下の `<Reducer名>.swift` に置く。
    public static func reducersArePlacedInFeatureDirs(
        in scope: HarmonizeScope,
        config: TCAArchConfig,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "reducer-placement",
            rationale: "ReducerはFeatures/<Name>/<Name>Feature.swift(composition rootはApp/)に置く。機能の変更が1フォルダに閉じ、将来のSPMモジュール分割と同型になる。"
        )
        topLevelReducerStructs(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { reducer in
            let placed = reducer.isUnder(config.featureDirs) || reducer.isUnder(config.appDirs)
            let named = reducer.declFileName == "\(reducer.name).swift"
            return placed && named
        }
    }

    /// R1c: 1ファイルにトップレベルReducerは1つまで(nested Destination/Pathは除く)。
    public static func oneReducerPerFile(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let reducers = topLevelReducerStructs(in: scope)
        var countByFile: [String: Int] = [:]
        for reducer in reducers {
            guard let path = reducer.sourceCodeLocation.sourceFilePath?.path else { continue }
            countByFile[path, default: 0] += 1
        }
        let rule = Rule(
            id: "one-reducer-per-file",
            rationale: "1ファイル1Reducer。複数Reducerの同居はファイルの肥大化と責務の混在を招く。"
        )
        reducers.assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { reducer in
            guard let path = reducer.sourceCodeLocation.sourceFilePath?.path else { return true }
            return countByFile[path] == 1
        }
    }

    /// R1d: Reducerを含むファイルにSwiftUI Viewを同居させない(Reducer/View別ファイルの原則)。
    public static func reducerFilesDoNotContainViews(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let viewFiles = Set(
            topLevelViewStructs(in: scope).compactMap { $0.sourceCodeLocation.sourceFilePath?.path }
        )
        let rule = Rule(
            id: "reducer-view-separation",
            rationale: "ReducerとViewは別ファイルに置く(Reducer=ロジック、View=表示の分離)。"
        )
        topLevelReducerStructs(in: scope).assertFalse(
            message: rule.rationale,
            rule: rule,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { reducer in
            guard let path = reducer.sourceCodeLocation.sourceFilePath?.path else { return false }
            return viewFiles.contains(path)
        }
    }

    /// R2: FeatureのStateは `@ObservableState` + `Equatable` のstructにする。
    ///
    /// Equatableは直接準拠のほか `extension XxxFeature.State: Equatable {}` も認める。
    public static func statesAreObservableAndEquatable(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        // out-of-body extensionによるEquatable準拠を許容するため、拡張を先に収集する
        let equatableExtensions = Set(
            scope.extensions()
                .filter { $0.conforms(to: "Equatable") }
                .compactMap { $0.typeAnnotation?.annotation }
        )
        let rule = Rule(
            id: "state-observable-equatable",
            rationale: "Stateは@ObservableState(observation対応)かつEquatable(TestStoreでのテスト可能性)を必須にする。"
        )
        topLevelReducerStructs(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { reducer in
            guard let state = reducer.structs.first(where: { $0.name == "State" }) else {
                // Stateを持たないReducer(全処理をdelegateする等)は稀。存在しないなら違反扱い。
                return false
            }
            let observable = state.hasAttribute("ObservableState")
            let equatable = state.conforms(to: "Equatable")
                || equatableExtensions.contains("\(reducer.name).State")
            return observable && equatable
        }
    }

    /// R3: Actionのトップレベルcaseは binding / view / internal / delegate / 子Reducer接続のみ。
    ///
    /// - `view` / `internal` / `delegate` は存在するなら nested enum `View` / `Internal` /
    ///   `Delegate`(`@CasePathable` 付き)を伴うこと。
    /// - 子Reducer接続 = associated valueの型に `Action` を含むcase
    ///   (`PresentationAction` / `StackAction` / `Scope` 子の `XxxFeature.Action` 等)。
    public static func actionsAreStructured(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "action-structured",
            rationale: "Actionは view(UI操作) / internal(effect結果) / delegate(親への通知) / binding / 子Reducer接続 に構造化する。フラットなcaseは禁止。"
        )
        topLevelReducerStructs(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { reducer in
            guard let action = reducer.enums.first(where: { $0.name == "Action" }) else {
                // Actionを持たないReducerは違反(空でもenum Actionは必要)
                return false
            }
            return isWellStructured(action: action)
        }
    }

    /// R4: `@Presents` は `destination`(Destination enum)と `alert` / `confirmationDialog` のみ。
    ///
    /// - Parameter permanentExceptions: 恒久的に許可する `@Presents` プロパティ
    ///   (`Reducer名: [プロパティ名]`)。「presentationではなくnavigation/ペイン状態」のような
    ///   設計判断で裸の@Presentsを保持するケースに使う。理由は呼び出し側にコメントで明文化すること。
    public static func presentationUsesDestinationEnum(
        in scope: HarmonizeScope,
        permanentExceptions: [String: [String]] = [:],
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "presentation-destination-enum",
            rationale: "子画面のpresentationは@Reducer enum Destinationに集約する。裸の@Presents varは子画面追加のたびに形が発散する。alert/confirmationDialogのみ例外。"
        )
        topLevelReducerStructs(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { reducer in
            guard let state = reducer.structs.first(where: { $0.name == "State" }) else { return true }
            let allowedExtras = permanentExceptions[reducer.name] ?? []
            let presented = state.variables.filter { $0.hasAttribute("Presents") }
            return presented.allSatisfy { variable in
                if allowedExtras.contains(variable.name) { return true }
                let type = variable.typeAnnotation?.annotation ?? ""
                switch variable.name {
                case "destination":
                    return type.contains("Destination.State")
                case "alert":
                    return type.contains("AlertState")
                case "confirmationDialog":
                    return type.contains("ConfirmationDialogState")
                default:
                    return false
                }
            }
        }
    }

    // MARK: - Action構造の判定

    /// Action enumが規約(3分割+子Reducer接続のみ)を満たすか。
    private static func isWellStructured(action: Enum) -> Bool {
        let allowedGroups: [String: String] = [
            "view": "View",
            "internal": "Internal",
            "delegate": "Delegate",
        ]
        let freeCaseNames: Set<String> = ["binding", "destination", "path", "alert", "confirmationDialog"]

        for enumCase in action.cases {
            let name = enumCase.name.replacingOccurrences(of: "`", with: "")
            let payloadTypes = enumCase.parameters.compactMap { $0.typeAnnotation?.annotation }

            if let groupTypeName = allowedGroups[name] {
                // view/internal/delegate: payloadが対応するnested enumで、@CasePathableが付いていること
                guard payloadTypes.count == 1,
                      payloadTypes[0].hasSuffix(groupTypeName),
                      let group = action.enums.first(where: { $0.name == groupTypeName }),
                      group.hasAttribute("CasePathable")
                else { return false }
                continue
            }
            if freeCaseNames.contains(name) {
                continue
            }
            // それ以外は子Reducer接続(型名にActionを含む)のみ許可
            let isChildConnection = payloadTypes.contains { $0.contains("Action") }
            if !isChildConnection { return false }
        }

        // viewグループを持つならViewActionプロトコルに準拠する(@ViewAction(for:)の前提)
        let hasViewCase = action.cases.contains {
            $0.name.replacingOccurrences(of: "`", with: "") == "view"
        }
        if hasViewCase, !action.conforms(to: "ViewAction") {
            return false
        }
        // bindingを持つならBindableActionに準拠する
        let hasBindingCase = action.cases.contains {
            $0.name.replacingOccurrences(of: "`", with: "") == "binding"
        }
        if hasBindingCase, !action.conforms(to: "BindableAction") {
            return false
        }
        return true
    }
}
