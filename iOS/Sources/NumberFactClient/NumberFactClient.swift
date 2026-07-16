import Dependencies
import DependenciesMacros
import Foundation

/// DependencyClientの実装例。外部の世界(ここではnumbersapi.com)との唯一の接点。
///
/// アーキテクチャルール(R6)の要点:
/// - `*Client` 命名、1ファイル1Client、専用ターゲットに置く
/// - 同一ファイルで `DependencyKey` 準拠+`liveValue`/`testValue`/`previewValue` の3値を明示する
/// - importは `Dependencies`/`DependenciesMacros` まで(`ComposableArchitecture` は禁止)
/// - Singleton(`URLSession.shared` 等)へのアクセスはliveValue実装の中に隔離する
@DependencyClient
public struct NumberFactClient: Sendable {
    public var fact: @Sendable (_ number: Int) async throws -> String
}

extension NumberFactClient: DependencyKey {
    public static let liveValue = NumberFactClient(
        fact: { number in
            guard let url = URL(string: "http://numbersapi.com/\(number)") else {
                throw URLError(.badURL)
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let fact = String(bytes: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            return fact
        }
    )

    /// @DependencyClientが生成するunimplementedなデフォルト(呼ばれたらテスト失敗)
    public static let testValue = NumberFactClient()

    public static let previewValue = NumberFactClient(
        fact: { "\($0) is a good number." }
    )
}

extension DependencyValues {
    public var numberFactClient: NumberFactClient {
        get { self[NumberFactClient.self] }
        set { self[NumberFactClient.self] = newValue }
    }
}
