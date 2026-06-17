import Foundation

public final class ConfigStore: @unchecked Sendable {
    public let url: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fallbackConfig: PathConverterConfig?

    public init(url: URL = ConfigStore.defaultConfigURL(), fallbackConfig: PathConverterConfig? = nil) {
        self.url = url
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.fallbackConfig = fallbackConfig
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public static func defaultConfigURL() -> URL {
        let environment = ProcessInfo.processInfo.environment
        if let configuredPath = environment["PATH_CONVERTER_CONFIG"], !configuredPath.isEmpty {
            return URL(fileURLWithPath: configuredPath)
        }

        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            return FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("PathConverter", isDirectory: true)
                .appendingPathComponent("config.json")
        }

        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("data", isDirectory: true)
            .appendingPathComponent("config.json")
    }

    public func load() -> PathConverterConfig {
        if let data = try? Data(contentsOf: url),
           let config = try? decoder.decode(PathConverterConfig.self, from: data) {
            return config
        }

        let configFileExists = FileManager.default.fileExists(atPath: url.path)
        let fallbackConfig = fallbackConfig ?? bundledConfig() ?? PathConverterConfig()
        if !configFileExists {
            try? save(fallbackConfig)
        }
        return fallbackConfig
    }

    public func save(_ config: PathConverterConfig) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
    }

    private func bundledConfig() -> PathConverterConfig? {
        if let bundledURL = Bundle.main.url(forResource: "config", withExtension: "json"),
           let data = try? Data(contentsOf: bundledURL),
           let config = try? decoder.decode(PathConverterConfig.self, from: data) {
            return config
        }

        return nil
    }
}
