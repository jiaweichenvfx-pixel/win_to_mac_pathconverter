import Foundation

public struct PathMapping: Codable, Equatable, Sendable {
    public var win: String
    public var mac: String

    private enum CodingKeys: String, CodingKey {
        case win
        case mac
    }

    public init(win: String, mac: String) {
        self.win = PathMapping.normalizeDrive(win)
        self.mac = PathMapping.normalizeMacPrefix(mac)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let win = try container.decode(String.self, forKey: .win)
        let mac = try container.decode(String.self, forKey: .mac)
        self.init(win: win, mac: mac)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(win, forKey: .win)
        try container.encode(mac, forKey: .mac)
    }

    public static let defaults: [PathMapping] = [
        PathMapping(win: "C", mac: ""),
        PathMapping(win: "P", mac: "/Volumes/projects"),
        PathMapping(win: "W", mac: "/Volumes/framestore")
    ]

    public static func normalizeDrive(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .uppercased()
    }

    public static func normalizeMacPrefix(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != "/" else { return trimmed }
        var normalized = trimmed
        while normalized.count > 1, normalized.last == "/" {
            normalized.removeLast()
        }
        return normalized
    }
}

public struct PathConverterConfig: Codable, Equatable, Sendable {
    public var mappings: [PathMapping]

    public init(mappings: [PathMapping] = PathMapping.defaults) {
        self.mappings = mappings
    }
}
