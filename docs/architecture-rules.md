# アーキテクチャルール

TCATemplateの静的解析は2層で運用する。**同じ意図のルールを両方に書かないこと**(二重管理の禁止)。

| 層 | ツール | 担当 | 実行タイミング |
|---|---|---|---|
| 構文・衛生 | SwiftLint (`.swiftlint.yml`) | 「書いた瞬間に気づきたい違反」。regexで安定して書けるもの | 毎ビルド(prebuildで `--fix` → `lint --lenient` 推奨)or 手動 |
| アーキテクチャ | Harmonize (`TCAArchRules` + `iOS/Tests/ArchitectureTests/ArchitectureTests.swift`) | 構造・存在・プロジェクト横断の照合。設計判断の違反 | テスト実行時 |

- SwiftLintはwarning運用(ビルドは落とさない)。厳格化(`--strict`)はCI側で行う想定。
- Harmonizeはテストなので違反=テスト失敗。**新規違反はマージ不可**が原則。

## baselineの運用(Harmonize)

各ルールは `baseline:` 引数で既知違反を登録できるが、**このテンプレートから作るアプリはbaseline空(=既知違反ゼロ)で始まる。空のまま保つこと。**

- baselineは「直すべきだが未着手」の既知違反リスト。**追加は原則禁止**(=アーキテクチャ違反を新たに増やすということ)。
- やむを得ず追加した場合も、違反を解消したらbaselineから**必ず削除する**。残すとstale検出でテストが落ちる(直し忘れではなく消し忘れを検出する仕組み)。
- つまりbaselineの行数 = 技術的負債の残量。増やさない・減る方向にしか動かせない。
- Apple APIの形状上どうしても消せない違反のみ、理由コメント付きで `permanentExceptions` に登録する(baselineとは区別する)。

## ルール一覧

### R1: Reducerの命名・配置(Harmonize)

- R1a `reducer-naming-feature-suffix`: `@Reducer` は `*Feature` 命名
- R1b `reducer-placement`: Reducerは `iOS/Sources/<ターゲット>/<Reducer名>.swift` に置く(ファイル名=Reducer名)
- R1c `one-reducer-per-file`: 1ファイル1Reducer(nested `Destination`/`Path` は除く)
- R1d `reducer-view-separation`: ReducerのファイルにViewを同居させない(`<Name>Feature.swift` + `<Name>View.swift` に分ける)

### R2: State規約(Harmonize)

- `state-observable-equatable`: Stateは `@ObservableState` + `Equatable`(TestStoreでのテスト可能性)。
  `@Reducer enum Destination` の生成Stateは `extension Xxx.Destination.State: Equatable {}` を明示する

### R3: Action構造(Harmonize)

- `action-structured`: Actionのトップレベルcaseは以下のみ
  - `binding(BindingAction<State>)`(使うなら `BindableAction` 準拠)
  - `view(View)`(使うなら `ViewAction` 準拠+View側に `@ViewAction(for:)`)
  - `internal(Internal)`(effect結果はすべてここ)
  - `delegate(Delegate)`(親への通知)
  - `destination` / `path` / `alert` / `confirmationDialog` / 子Reducer接続(`XxxFeature.Action` をpayloadに持つcase)
  - `View` / `Internal` / `Delegate` は存在するグループだけ定義(空enumの強制はしない)。定義するなら `@CasePathable` 必須

### R4: Presentation(Harmonize)

- `presentation-destination-enum`: `@Presents` を許すのは `destination`(`Destination.State?`)、
  `alert`(`AlertState`)、`confirmationDialog` のみ。子画面が1つでも `@Reducer enum Destination` を経由する

### R5: View層(Harmonize)

- R5a `view-no-dependency`: Viewは `@Dependency` を使わない
- R5b `store-creation-composition-root`: `Store(initialState:)` の生成はcomposition root(`AppRootView`)と `#Preview` のみ
- R5c `store-property-naming`: ViewのStoreOfプロパティ名は `store` 1つ
- R5d `view-action-macro`: `view(View)` を持つFeatureのViewは `@ViewAction(for:)` を付ける

### R6: Client規約(Harmonize)

- R6a `client-naming-suffix`: `@DependencyClient` は `*Client` 命名
- R6b `client-placement`: Clientは専用ターゲット(`iOS/Sources/<Name>Client/`)に1ファイル1Client
- R6c `client-dependency-values`: 同一ファイルで `DependencyKey` 準拠+`liveValue`/`testValue`/`previewValue` を明示
- R6d `dependency-accessor-naming`: `DependencyValues` アクセサ名は型名のlowerCamelCase
- R6e `client-no-tca-import`: Clientファイルは `ComposableArchitecture` をimportしない(`Dependencies`/`DependenciesMacros` まで)
- R6f `client-file-purity`: Clientファイルにドメイン型を同居させない(privateな実装ヘルパーのみ可。型は `Models/` へ)

### R7: レイヤーimport制限(Harmonize)

- R7a `db-import-confinement`: DBモジュール(`SQLiteData`/`GRDB`/`RealmSwift`)のimportは永続化層
  (`iOS/Sources/Persistence/`)+許可ファイル(DB導入時に `DatabaseClient.swift` 等を登録)のみ
- R7b `design-system-tca-free`: `DesignSystem/` はTCA/Dependencies非依存(純データ+クロージャのみ受け取る)
- R7c `models-tca-free`: `Models/` は `ComposableArchitecture` 非依存

### R8: Singleton/Manager隔離(Harmonize)

- R8a `no-singleton-access`: Reducer/Viewから `.shared` へのアクセス全面禁止(システムAPI含む)。ClientのliveValue実装に隔離
- R8b `no-direct-manager-access`: Reducer/Viewから `*Manager` の直接生成・参照禁止(Client経由)
- R8c `no-singleton-definition`: `static let shared` の新規定義禁止(共有状態はすべて `@Dependency` で注入)

### R9: テストカバレッジ(Harmonize)

- `reducer-test-coverage`: 全Reducerに対応する `<Reducer名>Tests` スイートが存在する(Swift Testing / XCTestどちらでも可)

### 衛生ルール(SwiftLint custom_rules)

- `no_print`: `print()` 禁止(os.Logger)
- `no_nondeterministic_api`: Feature内で `Date()`/`UUID()`/`Date.now` 禁止(`@Dependency(\.date)`/`(\.uuid)` 経由)
- `no_raw_task_in_feature`: Feature内で生 `Task {}`/`Task.detached` 禁止(`Effect.run` 経由)
- `no_dispatch_queue`: `DispatchQueue` 禁止(async/await + MainActor)
- `no_unchecked_sendable`: `@unchecked Sendable` 禁止(必要なら理由コメント+disable)
- `no_shared_key_literal`: `@Shared(.appStorage("リテラル"))` 禁止(キーは定数化)
- ほかopt-inビルトイン約25本(`.swiftlint.yml` 参照)

## モジュール構成(SPMターゲット分割)

このテンプレートは機能をディレクトリではなく**SPMターゲット**で分割する。
配置系ルール(R1b/R6b/R7)はこの構成を正とする。モジュール境界がimport制限を
コンパイルレベルでも強制するため、ディレクトリ分割より強い。

```
TCATemplate/
├── App/                      ← アプリシェル(XcodeGen生成。AppRootViewを表示するだけ)
├── iOS/
│   ├── Sources/
│   │   ├── AppFeature/       ← composition root(AppFeature + AppView + AppRootView)
│   │   ├── <Name>Feature/    ← 1機能1ターゲット(<Name>Feature.swift + <Name>View.swift)
│   │   ├── <Name>Client/     ← @DependencyClient(1ターゲット1Client。TCA本体に依存しない。
│   │   │                        実装例: NumberFactClient)
│   │   ├── DesignSystem/     ← TCA非依存の共有View部品(必要になったら作る)
│   │   ├── Models/           ← ドメインモデル(フレームワーク非依存。必要になったら作る)
│   │   └── Persistence/      ← DBモジュールのimportはここに閉じる(必要になったら作る)
│   └── Tests/
│       ├── <Name>FeatureTests/   ← Reducerのテスト(Swift Testing)
│       └── ArchitectureTests/    ← このルール集の実行(Harmonize)
└── TCAArchRules/             ← ルール実装(Harmonizeベース。プロジェクト非依存)
```

## 新しいFeature/Clientを追加するときの手順

1. `iOS/Sources/<Name>Feature/` に `<Name>Feature.swift`(Reducer)と `<Name>View.swift`(View)を作る
2. `iOS/Package.swift` にtargetとproduct(必要なら)を追加する
3. `iOS/Tests/<Name>FeatureTests/` に `<Name>FeatureTests` スイートを作る(R9で強制される)
4. Clientが必要なら `iOS/Sources/<Name>Client/<Name>Client.swift` を作る
   (`Dependencies`/`DependenciesMacros` のみimport、liveValue/testValue/previewValueを明示)
5. `swift test --package-path iOS` を回す。ArchitectureTestsが落ちたらbaselineに逃げず、コードを直す

## 他のTCAアプリへの展開手順

1. `TCAArchRules/` をコピー(将来的には別リポジトリ化してSPM参照)
2. リポジトリルートに `.harmonize.yaml` を置く(除外パスを設定)
3. テストターゲットに `TCAArchRules` パッケージを依存追加
4. `ArchitectureTests.swift` をコピーし、`TCAArchConfig` のパスを自分のプロジェクトに合わせる
   (新規アプリならbaselineは全部空で始められる)
5. `.swiftlint.yml` をコピー(custom_rulesの `included` パスを調整)

## 実行方法

```bash
# 全テスト(Reducerテスト+アーキテクチャテスト)
# NOTE: Xcode 27 betaのツールチェーンは依存パッケージのビルドとテスト実行が不安定なため26.5を使用
DEVELOPER_DIR=/Applications/Xcode-26.5.0.app swift test --package-path iOS

# アーキテクチャテストのみ
DEVELOPER_DIR=/Applications/Xcode-26.5.0.app swift test --package-path iOS --filter ArchitectureTests

# SwiftLint(手動)
swiftlint lint --quiet --lenient
```
