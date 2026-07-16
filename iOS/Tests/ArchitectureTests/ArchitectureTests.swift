import Foundation
import Harmonize
import TCAArchRules
import Testing

/// TCATemplateのアーキテクチャルール(Harmonizeベースの静的解析)。
///
/// ルール本体は `TCAArchRules` パッケージにあり、このファイルはテンプレートの
/// パス設定を渡して実行する。詳細な分担表と各ルールの意図は `docs/architecture-rules.md` を参照。
///
/// ## baselineの運用
/// - このテンプレートから作るアプリはbaseline空(=既知違反ゼロ)で始まる。**空のまま保つこと**。
/// - baselineへの追加はアーキテクチャ違反を新たに増やすということ。原則禁止。
/// - やむを得ず追加した場合も、違反を解消したらbaselineから**必ず**削除する
///   (残すとstale検出でテストが落ちる)。
///
/// NOTE: `.serialized` は必須。Harmonizeのソーススキャン(warmUp)は並列テスト実行下で
/// デッドロックするため、このスイートのテストは直列で実行する。
@Suite("アーキテクチャルール", .serialized)
struct ArchitectureTests {
    /// テンプレートのSPMモジュール構成。
    ///
    /// - Feature = `iOS/Sources/<Name>Feature` ターゲット(`<Name>Feature.swift` + `<Name>View.swift`)
    /// - Client = `iOS/Sources/<Name>Client` ターゲット(1ターゲット1Client)。
    ///   `clientDirs` は `iOS/Sources/` 全体を指すが、SPMのモジュール境界が
    ///   「Clientは専用ターゲットに置く」ことを強制するため、これで十分
    /// - composition root = `AppFeature` ターゲット + `App/` のアプリシェル
    ///
    /// NOTE: instanceプロパティにしているのはSwift 6モードでの制約
    /// (TCAArchConfigはSendable宣言を持たないため、static letはconcurrency-safeエラーになる)
    private let config = TCAArchConfig(
        featureDirs: ["iOS/Sources/"],
        appDirs: ["iOS/Sources/AppFeature/", "App/"],
        clientDirs: ["iOS/Sources/"],
        designSystemDirs: ["iOS/Sources/DesignSystem/"],
        modelDirs: ["iOS/Sources/Models/"],
        persistenceDirs: ["iOS/Sources/Persistence/"],
        dbModules: ["SQLiteData", "GRDB", "RealmSwift"],
        // DBを導入したら、ブートストラップを担うファイル(DatabaseClient.swift等)をここに追加する
        dbImportAllowedFiles: [],
        storeCreationAllowedTypes: ["AppRootView"]
    )

    private var scope: HarmonizeScope { Harmonize.productionCode() }
    private var testScope: HarmonizeScope { Harmonize.testCode() }

    // MARK: - R1: Reducerの命名・配置

    @Test("R1a: @Reducerは*Feature命名")
    func reducerNaming() {
        ReducerRules.reducersAreSuffixedFeature(in: scope)
    }

    @Test("R1b: Reducerは<Reducer名>.swiftに置く")
    func reducerPlacement() {
        ReducerRules.reducersArePlacedInFeatureDirs(in: scope, config: config)
    }

    @Test("R1c: 1ファイル1Reducer")
    func oneReducerPerFile() {
        ReducerRules.oneReducerPerFile(in: scope)
    }

    @Test("R1d: ReducerのファイルにViewを同居させない")
    func reducerViewSeparation() {
        ReducerRules.reducerFilesDoNotContainViews(in: scope)
    }

    // MARK: - R2: State規約

    @Test("R2: Stateは@ObservableState+Equatable")
    func stateShape() {
        ReducerRules.statesAreObservableAndEquatable(in: scope)
    }

    // MARK: - R3: Action構造

    @Test("R3: Actionはview/internal/delegate/binding/子Reducer接続のみ")
    func actionStructure() {
        ReducerRules.actionsAreStructured(in: scope)
    }

    // MARK: - R4: Presentation

    @Test("R4: @Presentsはdestination/alert/confirmationDialogのみ")
    func presentationShape() {
        ReducerRules.presentationUsesDestinationEnum(in: scope)
    }

    // MARK: - R5: View層

    @Test("R5a: Viewは@Dependencyを使わない")
    func viewDependencies() {
        ViewRules.viewsDoNotUseDependencies(in: scope)
    }

    @Test("R5b: Store生成はcomposition rootと#Previewのみ")
    func storeCreation() {
        ViewRules.storesAreCreatedOnlyInCompositionRoot(in: scope, config: config)
    }

    @Test("R5c: ViewのStoreOfプロパティ名はstore")
    func storePropertyNaming() {
        // NOTE: 型注釈のないStore生成(@State var x = Store(...))はこのルールでは検出できない。
        // その形はR5b(store-creation-composition-root)が捕捉する
        ViewRules.storePropertiesAreNamedStore(in: scope)
    }

    @Test("R5d: view(View)を持つFeatureのViewは@ViewAction")
    func viewActionMacro() {
        ViewRules.viewsUseViewActionMacro(in: scope)
    }

    // MARK: - R6: Client規約

    @Test("R6a: @DependencyClientは*Client命名")
    func clientNaming() {
        ClientRules.clientsAreSuffixedClient(in: scope)
    }

    @Test("R6b: Clientは専用ターゲットに1ファイル1つ")
    func clientPlacement() {
        ClientRules.clientsArePlacedInClientDirs(in: scope, config: config)
    }

    @Test("R6c: ClientはliveValue/testValue/previewValueを明示")
    func clientDependencyValues() {
        ClientRules.clientsProvideAllDependencyValues(in: scope)
    }

    @Test("R6d: DependencyValuesアクセサ名は型名のlowerCamelCase")
    func dependencyAccessorNaming() {
        ClientRules.dependencyValuesAccessorsMatchTypeNames(in: scope)
    }

    @Test("R6e: ClientファイルはComposableArchitectureをimportしない")
    func clientImports() {
        ClientRules.clientFilesDoNotImportTCA(in: scope)
    }

    @Test("R6f: Clientファイルにドメイン型を同居させない")
    func clientFilePurity() {
        ClientRules.clientFilesContainOnlyClients(in: scope)
    }

    // MARK: - R7: レイヤーimport制限

    @Test("R7a: DBモジュールのimportは永続化層に閉じる")
    func dbImports() {
        LayerRules.dbImportsAreConfinedToPersistence(in: scope, config: config)
    }

    @Test("R7b: DesignSystemはTCA非依存")
    func designSystemImports() {
        LayerRules.designSystemIsTCAFree(in: scope, config: config)
    }

    @Test("R7c: ModelsはTCA非依存")
    func modelImports() {
        LayerRules.modelsAreTCAFree(in: scope, config: config)
    }

    // MARK: - R8: Singleton/Manager隔離

    @Test("R8a: Reducer/Viewは.sharedにアクセスしない")
    func singletonAccess() {
        // permanentExceptionsはApple APIの形状上`.shared`を消せないファイル(恒久例外)にのみ使う。
        // 追加する場合は理由をここに明記すること
        LayerRules.featuresDoNotAccessSingletons(in: scope)
    }

    @Test("R8b: Reducer/ViewはManagerを直接参照しない")
    func managerAccess() {
        LayerRules.featuresDoNotTouchManagers(in: scope)
    }

    @Test("R8c: Singletonを新規定義しない")
    func singletonDefinitions() {
        LayerRules.noNewSingletonDefinitions(in: scope)
    }

    // MARK: - R9: テストカバレッジ

    @Test("R9: 全Reducerに対応する<Name>Testsスイートが存在する")
    func testCoverage() {
        TestCoverageRules.reducersHaveTestSuites(in: scope, testScope: testScope)
    }
}
