import Foundation
import Harmonize
import HarmonizeSemantics

/// DependencyClient層に関するルール群。
///
/// アサート対象はトップレベルの `@DependencyClient` struct。baselineにはClient名を書く。
public enum ClientRules {
    /// R6a: `@DependencyClient` 型は `*Client` 命名にする。
    public static func clientsAreSuffixedClient(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "client-naming-suffix",
            rationale: "依存クライアントは<Domain>Client命名に統一する。"
        )
        topLevelDependencyClients(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { $0.name.hasSuffix("Client") }
    }

    /// R6b: Clientは `clientDirs` 配下に置き、1ファイル1Clientにする。
    public static func clientsArePlacedInClientDirs(
        in scope: HarmonizeScope,
        config: TCAArchConfig,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let clients = topLevelDependencyClients(in: scope)
        var countByFile: [String: Int] = [:]
        for client in clients {
            guard let path = client.sourceCodeLocation.sourceFilePath?.path else { continue }
            countByFile[path, default: 0] += 1
        }
        let rule = Rule(
            id: "client-placement",
            rationale: "ClientはClients/<Name>Client.swiftに1つずつ置く。型の居場所が予測可能になる。"
        )
        clients.assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { client in
            guard let path = client.sourceCodeLocation.sourceFilePath?.path else { return true }
            return client.isUnder(config.clientDirs) && countByFile[path] == 1
        }
    }

    /// R6c: Clientは同一ファイル内で `DependencyKey` に準拠し、
    /// `liveValue` / `testValue` / `previewValue` の3値を明示的に定義する。
    public static func clientsProvideAllDependencyValues(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let extensions = scope.extensions()
        let rule = Rule(
            id: "client-dependency-values",
            rationale: "ClientはDependencyKey準拠でliveValue/testValue/previewValueを明示する。previewValue = testValueのエイリアスは可。"
        )
        topLevelDependencyClients(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { client in
            let keyExtensions = extensions.filter {
                $0.typeAnnotation?.annotation == client.name && $0.conforms(to: "DependencyKey")
            }
            let definedValues = Set(keyExtensions.flatMap { $0.variables.map(\.name) })
            return ["liveValue", "testValue", "previewValue"].allSatisfy(definedValues.contains)
        }
    }

    /// R6d: `DependencyValues` のアクセサ名は型名のlowerCamelCaseにする
    /// (例: `DatabaseClient` → `var databaseClient`)。
    public static func dependencyValuesAccessorsMatchTypeNames(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let accessorNames = Set(
            scope.extensions()
                .filter { $0.typeAnnotation?.annotation == "DependencyValues" }
                .flatMap { $0.variables.map(\.name) }
        )
        let rule = Rule(
            id: "dependency-accessor-naming",
            rationale: "@Dependency(\\.xxxClient)のキー名は型名のlowerCamelCaseに統一する(検索可能性と一意性)。"
        )
        topLevelDependencyClients(in: scope).assertTrue(
            message: rule.rationale,
            rule: rule,
            strict: true,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { client in
            accessorNames.contains(accessorName(forTypeName: client.name))
        }
    }

    /// R6e: Clientのファイルは `ComposableArchitecture` をimportしない。
    ///
    /// Clientが依存してよいのはDependencies/DependenciesMacrosまで。TCA本体への依存は
    /// Client層をFeature層に癒着させる。
    public static func clientFilesDoNotImportTCA(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "client-no-tca-import",
            rationale: "ClientはDependencies/DependenciesMacrosのみに依存する。ComposableArchitectureのimportは不要な結合。"
        )
        let sourcesByPath = Dictionary(
            uniqueKeysWithValues: scope.sources().compactMap { source -> (String, SwiftSourceCode)? in
                guard let path = source.filePath?.path else { return nil }
                return (path, source)
            }
        )
        topLevelDependencyClients(in: scope).assertFalse(
            message: rule.rationale,
            rule: rule,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { client in
            guard let path = client.sourceCodeLocation.sourceFilePath?.path,
                  let source = sourcesByPath[path] else { return false }
            return source.imports().contains { $0.name == "ComposableArchitecture" }
        }
    }

    /// R6f: Clientファイルにドメイン型を同居させない。
    ///
    /// Clientファイルに置けるトップレベル型はClient本体のみ(private/fileprivateな実装ヘルパーは可)。
    /// Clientが返すドメイン型はModels/に置く。
    public static func clientFilesContainOnlyClients(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let clientFiles = Set(
            topLevelDependencyClients(in: scope).compactMap { $0.sourceCodeLocation.sourceFilePath?.path }
        )
        let rule = Rule(
            id: "client-file-purity",
            rationale: "Clientファイルにドメイン型を同居させない。型はModels/へ。privateな実装ヘルパーのみ同居可。"
        )

        func isViolation(_ declaration: some Declaration & AttributesProviding & ModifiersProviding & SourceCodeProviding & NamedDeclaration & ParentDeclarationProviding) -> Bool {
            // nested型は親型の実装詳細なので対象外(トップレベル型のみ検査)
            guard declaration.parent == nil,
                  let path = declaration.sourceCodeLocation.sourceFilePath?.path,
                  clientFiles.contains(path) else { return false }
            if declaration.hasAttribute("DependencyClient") { return false }
            let isPrivate = declaration.modifiers.contains { $0 == .private || $0 == .fileprivate }
            return !isPrivate
        }

        let structs = scope.structs(includeNested: false).filter { $0.parent == nil }
        let classes = scope.classes(includeNested: false).filter { $0.parent == nil }
        let enums = scope.enums(includeNested: false).filter { $0.parent == nil }

        structs.assertFalse(
            message: rule.rationale, rule: rule, baseline: structs.relevantBaseline(baseline),
            fileID: fileID, file: file, line: line, column: column
        ) { isViolation($0) }

        classes.assertFalse(
            message: rule.rationale, rule: rule, baseline: classes.relevantBaseline(baseline),
            fileID: fileID, file: file, line: line, column: column
        ) { isViolation($0) }

        enums.assertFalse(
            message: rule.rationale, rule: rule, baseline: enums.relevantBaseline(baseline),
            fileID: fileID, file: file, line: line, column: column
        ) { isViolation($0) }
    }
}
