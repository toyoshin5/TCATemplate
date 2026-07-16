import Foundation
import Harmonize
import HarmonizeSemantics

/// テストカバレッジ(構造レベル)に関するルール群。
public enum TestCoverageRules {
    /// R9: 全Reducerに対応するテストスイート(`<Reducer名>Tests`)が存在する。
    ///
    /// - Parameters:
    ///   - scope: プロダクションコードのスコープ。
    ///   - testScope: テストコードのスコープ(`Harmonize.testCode()`)。
    ///   - baseline: 未カバーの既知Reducer名。
    public static func reducersHaveTestSuites(
        in scope: HarmonizeScope,
        testScope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        // Swift Testing(@Suite struct)とXCTest(class)の両方を候補にする
        let suiteNames = Set(
            testScope.structs(includeNested: false).map(\.name)
                + testScope.classes(includeNested: false).map(\.name)
        )
        let rule = Rule(
            id: "reducer-test-coverage",
            rationale: "全Reducerに<Reducer名>Testsスイートを必須にする。テスト無しのFeature追加を機械的に検出する。"
        )
        topLevelReducerStructs(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { reducer in
            suiteNames.contains("\(reducer.name)Tests")
        }
    }
}
