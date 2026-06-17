import Foundation
import Testing
@testable import PathConverterCore

@Suite("Config store")
struct ConfigStoreTests {
    @Test("Missing config is created from fallback")
    func missingConfigIsCreatedFromFallback() throws {
        let directory = try temporaryDirectory()
        let url = directory.appendingPathComponent("config.json")
        let fallback = PathConverterConfig(mappings: [
            PathMapping(win: "Z", mac: "/Volumes/custom")
        ])
        let store = ConfigStore(url: url, fallbackConfig: fallback)

        let loaded = store.load()

        #expect(loaded == fallback)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("Invalid existing config is not overwritten")
    func invalidExistingConfigIsNotOverwritten() throws {
        let directory = try temporaryDirectory()
        let url = directory.appendingPathComponent("config.json")
        let invalidJSON = #"{"mappings": ["#
        try invalidJSON.write(to: url, atomically: true, encoding: .utf8)
        let fallback = PathConverterConfig(mappings: [
            PathMapping(win: "Z", mac: "/Volumes/custom")
        ])
        let store = ConfigStore(url: url, fallbackConfig: fallback)

        let loaded = store.load()
        let currentContents = try String(contentsOf: url, encoding: .utf8)

        #expect(loaded == fallback)
        #expect(currentContents == invalidJSON)
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PathConverterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
