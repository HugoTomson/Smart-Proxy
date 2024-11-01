import Foundation

public struct Config: Codable , Equatable {
    public let config: String

    public init(config: String) {
        self.config = config
    }
}
