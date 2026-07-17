import Foundation
import Harmonize
import HarmonizeSemantics

/// レイヤー境界(import制限・Singleton/Manager隔離)に関するルール群。
public enum LayerRules {
    /// R7a: DBモジュール(`config.dbModules`)のimportは永続化層と許可ファイルのみ。
    ///
    /// baselineにはファイル名(例: `"SampleDataMode.swift"`)を書く。
    public static func dbImportsAreConfinedToPersistence(
        in scope: HarmonizeScope,
        config: TCAArchConfig,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "db-import-confinement",
            rationale: "DBモジュールのimportはPersistence配下とDatabaseClient/MigrationClient等の許可ファイルに閉じる。DBアクセス経路を一本化するため。"
        )
        scope.imports()
            .filter { config.dbModules.contains($0.name) }
            .assertTrue(
                message: rule.rationale,
                rule: rule,
                baseline: baseline,
                fileID: fileID, file: file, line: line, column: column
            ) { importDecl in
                if importDecl.isUnder(config.persistenceDirs) { return true }
                guard let fileName = importDecl.declFileName else { return true }
                return config.dbImportAllowedFiles.contains(fileName)
            }
    }

    /// R7b: DesignSystem(共有UI部品)層はTCA/Dependenciesに依存しない。
    ///
    /// 部品は純粋なデータとクロージャだけを受け取る。Storeや@Dependencyが必要になったら
    /// それはFeature専用Viewであり、Features/配下に置くべきサイン。
    public static func designSystemIsTCAFree(
        in scope: HarmonizeScope,
        config: TCAArchConfig,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let forbidden: Set<String> = ["ComposableArchitecture", "Dependencies", "DependenciesMacros"]
        let rule = Rule(
            id: "design-system-tca-free",
            rationale: "DesignSystemの部品は純粋なデータ+クロージャのみを受け取る。TCA依存が要るならそれはFeature専用View。"
        )
        scope.imports()
            .filter { $0.isUnder(config.designSystemDirs) }
            .assertFalse(
                message: rule.rationale,
                rule: rule,
                baseline: baseline,
                fileID: fileID, file: file, line: line, column: column
            ) { forbidden.contains($0.name) }
    }

    /// R7c: Models(ドメインモデル)層はComposableArchitectureに依存しない。
    public static func modelsAreTCAFree(
        in scope: HarmonizeScope,
        config: TCAArchConfig,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "models-tca-free",
            rationale: "ドメインモデルはフレームワーク非依存に保つ。"
        )
        scope.imports()
            .filter { $0.isUnder(config.modelDirs) }
            .assertFalse(
                message: rule.rationale,
                rule: rule,
                baseline: baseline,
                fileID: fileID, file: file, line: line, column: column
            ) { $0.name == "ComposableArchitecture" }
    }

    /// R7e: Feature層は永続化・OS・外部SDKの直接APIを参照しない。
    ///
    /// Featureは`@Shared`または`@Dependency`のClientを経由して副作用へアクセスする。
    /// App層はcomposition rootとして許可し、Client層はliveValue実装の担当として許可する。
    public static func featuresDoNotAccessDirectSideEffects(
        in scope: HarmonizeScope,
        config: TCAArchConfig,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let forbiddenImports: Set<String> = [
            "CloudKit",
            "FirebaseAuth",
            "FirebaseFirestore",
            "GoogleMobileAds",
            "GRDB",
            "RealmSwift",
            "RevenueCat",
            "SQLiteData",
            "StoreKit",
            "SwiftData"
        ]
        let importRule = Rule(
            id: "feature-no-side-effect-imports",
            rationale: "Feature層は外部SDK/永続化モジュールを直接importせず、Client経由で利用する。"
        )
        let featureFiles = featureAndViewFiles(in: scope).filter { source in
            guard let path = source.filePath?.path else { return false }
            return !config.appDirs.contains { path.contains("/\($0)") }
        }
        let featureFilePaths = Set(featureFiles.compactMap { $0.filePath?.path })
        scope.imports()
            .filter { importDecl in
                guard let path = importDecl.sourceCodeLocation.sourceFilePath?.path else { return false }
                return featureFilePaths.contains(path)
            }
            .assertFalse(
                message: importRule.rationale,
                rule: importRule,
                baseline: baseline,
                fileID: fileID, file: file, line: line, column: column
            ) { forbiddenImports.contains($0.name) }

        let forbiddenTokens = [
            "UserDefaults",
            "FileManager.default",
            "URLSession.shared",
            "UIApplication.shared",
            "UIDevice.current",
            "WidgetCenter.shared",
            "UNUserNotificationCenter.current",
            "Purchases.shared",
            "Firestore.firestore"
        ]
        let accessRule = Rule(
            id: "feature-no-direct-side-effects",
            rationale: "Feature層は永続化・OS・外部SDKの直接APIを使わず、@SharedまたはClientを経由する。"
        )
        featureFiles
            .assertFalse(
                message: accessRule.rationale,
                rule: accessRule,
                baseline: baseline,
                fileID: fileID, file: file, line: line, column: column
            ) { source in
                forbiddenTokens.contains { source.source.contains($0) }
            }
    }

    /// R8a: Feature/View層のファイルは `.shared`(Singleton)へアクセスしない。
    ///
    /// システムAPI(UIApplication.shared等)も含めて全面禁止。副作用はClientのliveValue実装に隔離する。
    /// ファイル単位で検査する(トップレベル関数やローカル宣言での違反も捕捉するため)。
    /// baselineにはファイル名を書く。
    /// - Parameter permanentExceptions: 恒久的に検査対象から外すファイル名。
    ///   Apple APIが要求する形(PhotosPickerの`.shared()`等)でどうしても消せないケースに使う。
    ///   理由は呼び出し側にコメントで明文化すること。
    public static func featuresDoNotAccessSingletons(
        in scope: HarmonizeScope,
        permanentExceptions: [String] = [],
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "no-singleton-access",
            rationale: "Reducer/Viewから.sharedへの直接アクセス禁止。副作用の経路が@Dependencyの外にできるとテストで差し替えられない。"
        )
        featureAndViewFiles(in: scope)
            .filter { source in
                guard let name = source.fileName else { return true }
                return !permanentExceptions.contains(name)
            }
            .assertFalse(
                message: rule.rationale,
                baseline: baseline,
                fileID: fileID, file: file, line: line, column: column
            ) { source in
                source.source.contains(".shared")
            }
    }

    /// R8b: Feature/View層のファイルは `*Manager` を直接参照しない(Client経由必須)。
    ///
    /// ファイル単位で検査する。baselineにはファイル名を書く。
    public static func featuresDoNotTouchManagers(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "no-direct-manager-access",
            rationale: "ManagerはClientのliveValue実装の詳細。Reducer/Viewからの直接生成・参照はDIを迂回する。"
        )
        featureAndViewFiles(in: scope).assertFalse(
            message: rule.rationale,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { source in
            // "Manager(" = 直接生成、"Manager." = static/singletonアクセス
            source.source.contains("Manager(") || source.source.contains("Manager.")
        }
    }

    /// R8c: Singleton(`static let shared` / `static var shared`)を新規に定義しない。
    ///
    /// 定義箇所の変数を直接検査する(class/struct/actorすべての中を捕捉するため)。
    /// baselineにはファイル名(例: `"PermissionManager.swift"`)を書く。
    public static func noNewSingletonDefinitions(
        in scope: HarmonizeScope,
        baseline: [String] = [],
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let rule = Rule(
            id: "no-singleton-definition",
            rationale: "共有状態はSingletonではなく@Dependencyで注入する。ライフサイクルとテスト差し替えを制御下に置くため。"
        )
        let sharedDefinitions = scope.variables(includeNested: true).filter {
            $0.name == "shared" && $0.modifiers.contains(.static)
        }
        sharedDefinitions.assertFalse(
            message: rule.rationale,
            rule: rule,
            baseline: baseline,
            fileID: fileID, file: file, line: line, column: column
        ) { _ in true }
    }
}
