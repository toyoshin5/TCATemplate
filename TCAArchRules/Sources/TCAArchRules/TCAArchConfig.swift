import Foundation
import Harmonize
import HarmonizeSemantics

/// TCAアプリのアーキテクチャルールに渡すプロジェクト固有設定。
///
/// パスは「リポジトリルートからの相対パス断片」で指定する(例: `"TwiNotes/Features/"`)。
/// 判定は `sourceFilePath.path.contains("/" + 断片)` で行うため、末尾に `/` を付けること。
public struct TCAArchConfig {
    /// Feature(Reducer+View)を配置するディレクトリ群。
    public var featureDirs: [String]
    /// composition root(App エントリポイント)のディレクトリ群。Reducer配置も許可される。
    public var appDirs: [String]
    /// DependencyClient を配置するディレクトリ群。
    public var clientDirs: [String]
    /// TCA非依存の共有UI部品ディレクトリ群。
    public var designSystemDirs: [String]
    /// ドメインモデルのディレクトリ群。
    public var modelDirs: [String]
    /// 永続化層のディレクトリ群。DBモジュールのimportはここに閉じる。
    public var persistenceDirs: [String]
    /// DBアクセス用モジュール名。`persistenceDirs` と `dbImportAllowedFiles` 以外でのimportを禁止する。
    public var dbModules: [String]
    /// `persistenceDirs` 外でDBモジュールのimportを許可するファイル名(DatabaseClient.swift等)。
    public var dbImportAllowedFiles: [String]
    /// `Store(initialState:)` の生成を許可する型名(composition rootの型)。
    public var storeCreationAllowedTypes: [String]

    public init(
        featureDirs: [String],
        appDirs: [String],
        clientDirs: [String],
        designSystemDirs: [String],
        modelDirs: [String],
        persistenceDirs: [String],
        dbModules: [String] = ["RealmSwift", "SQLiteData", "GRDB"],
        dbImportAllowedFiles: [String] = [],
        storeCreationAllowedTypes: [String] = []
    ) {
        self.featureDirs = featureDirs
        self.appDirs = appDirs
        self.clientDirs = clientDirs
        self.designSystemDirs = designSystemDirs
        self.modelDirs = modelDirs
        self.persistenceDirs = persistenceDirs
        self.dbModules = dbModules
        self.dbImportAllowedFiles = dbImportAllowedFiles
        self.storeCreationAllowedTypes = storeCreationAllowedTypes
    }
}

// MARK: - 内部ヘルパー

extension SourceCodeProviding {
    /// この宣言のファイルパスが指定ディレクトリ断片のいずれかに含まれるか。
    func isUnder(_ dirFragments: [String]) -> Bool {
        guard let path = sourceCodeLocation.sourceFilePath?.path else { return false }
        return dirFragments.contains { path.contains("/" + $0) }
    }

    /// この宣言が属するファイル名(例: `PostingFeature.swift`)。
    var declFileName: String? {
        sourceCodeLocation.sourceFilePath?.lastPathComponent
    }
}

extension Array where Element: NamedDeclaration & SourceCodeProviding {
    /// この配列の要素に実際にマッチするbaselineエントリだけを返す。
    /// 1つのbaselineを複数のassert(structs/classes/enums等)に分配するとき、
    /// 他方のコレクションにしか存在しないエントリが「unmatched」誤報告されるのを防ぐ。
    func relevantBaseline(_ baseline: [String]) -> [String] {
        baseline.filter { entry in
            contains { $0.name == entry || $0.declFileName == entry }
        }
    }
}

extension AttributesProviding {
    /// `@Reducer` のような属性が付いているか(`@`の有無を吸収)。
    func hasAttribute(_ name: String) -> Bool {
        attributes.contains { $0.name == name || $0.name == "@" + name }
    }
}

/// 型名をDependencyValuesアクセサ名(lowerCamelCase)へ変換する。
/// 先頭の大文字連続(acronym)も正しく処理する。
/// 例: `DatabaseClient` → `databaseClient`、`URLOpenClient` → `urlOpenClient`
func accessorName(forTypeName typeName: String) -> String {
    let uppercasePrefix = typeName.prefix { $0.isUppercase }
    switch uppercasePrefix.count {
    case 0:
        return typeName
    case 1:
        return uppercasePrefix.lowercased() + typeName.dropFirst()
    case typeName.count:
        // 全部大文字(URL等)
        return typeName.lowercased()
    default:
        // 大文字連続の最後の1文字は次の単語の頭(URLOpen → url + Open)
        let lowered = uppercasePrefix.dropLast().lowercased()
        return lowered + typeName.dropFirst(lowered.count)
    }
}

// NOTE: Harmonizeの `includeNested: false` は型内nested宣言を除外しないため、
// トップレベル判定は `parent == nil` で行う。

/// スコープ内のトップレベル `@Reducer` struct を返す。
func topLevelReducerStructs(in scope: HarmonizeScope) -> [Struct] {
    scope.structs(includeNested: false).filter { $0.parent == nil && $0.hasAttribute("Reducer") }
}

/// スコープ内のトップレベル `@Reducer` enum を返す(通常はDestination/Pathはnestedなので空)。
func topLevelReducerEnums(in scope: HarmonizeScope) -> [Enum] {
    scope.enums(includeNested: false).filter { $0.parent == nil && $0.hasAttribute("Reducer") }
}

/// スコープ内のView層struct(`View` / `ViewModifier` 準拠のトップレベルstruct)を返す。
func topLevelViewStructs(in scope: HarmonizeScope) -> [Struct] {
    scope.structs(includeNested: false).filter {
        $0.parent == nil && ($0.conforms(to: "View") || $0.conforms(to: "ViewModifier"))
    }
}

/// スコープ内のトップレベル `@DependencyClient` struct を返す。
func topLevelDependencyClients(in scope: HarmonizeScope) -> [Struct] {
    scope.structs(includeNested: false).filter { $0.parent == nil && $0.hasAttribute("DependencyClient") }
}

/// Reducer(Feature)またはViewを含むファイル群を返す。
/// 「Feature/View層のコード」をファイル単位で検査するルール(Singleton/Manager禁止等)に使う。
/// struct単位の検査ではファイル内のトップレベル関数やローカル宣言での違反を見逃すため。
func featureAndViewFiles(in scope: HarmonizeScope) -> [SwiftSourceCode] {
    let targetPaths = Set(
        (topLevelReducerStructs(in: scope).map { $0.sourceCodeLocation.sourceFilePath?.path }
            + topLevelViewStructs(in: scope).map { $0.sourceCodeLocation.sourceFilePath?.path })
            .compactMap { $0 }
    )
    return scope.sources().filter { source in
        guard let path = source.filePath?.path else { return false }
        return targetPaths.contains(path)
    }
}
