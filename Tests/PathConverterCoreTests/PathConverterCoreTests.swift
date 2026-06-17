import Testing
@testable import PathConverterCore

@Suite("Path conversion")
struct PathConverterCoreTests {
    private let converter = PathConverter(mappings: PathMapping.defaults)

    @Test("Windows mapped drive converts to configured Mac prefix")
    func windowsMappedDriveConvertsToMac() throws {
        let result = try #require(converter.convertWindowsToMac("P:\\shots\\seq\\shot_001"))

        #expect(result.source == "P:\\shots\\seq\\shot_001")
        #expect(result.converted == "/Volumes/projects/shots/seq/shot_001")
        #expect(result.drive == "P")
        #expect(result.mappingLabel == "P: -> /Volumes/projects")
    }

    @Test("Windows unknown drive falls back to matching Volumes drive")
    func unknownWindowsDriveFallsBackToVolumesDrive() throws {
        let result = try #require(converter.convertWindowsToMac("D:/cache/sim.vdb"))

        #expect(result.converted == "/Volumes/D/cache/sim.vdb")
        #expect(result.mappingLabel == "D: -> /Volumes/D")
    }

    @Test("Ignored Windows drive returns no conversion")
    func ignoredWindowsDriveReturnsNoConversion() {
        #expect(converter.convertWindowsToMac("C:\\Users\\artist\\Desktop") == nil)
    }

    @Test("Mac mapped prefix only detects prompt without default reverse conversion")
    func macMappedPrefixDetectsPromptWithoutDefaultReverseConversion() throws {
        let prompt = try #require(converter.detectMacPathPrompt("/Volumes/projects/shots/seq/shot_001"))

        #expect(prompt.source == "/Volumes/projects/shots/seq/shot_001")
        #expect(prompt.drive == "P")
        #expect(prompt.mappingLabel == "P: -> /Volumes/projects")
        #expect(prompt.converted == nil)
    }

    @Test("Explicit Mac to Windows conversion reverses configured mapping")
    func explicitMacToWindowsConversionReversesMapping() throws {
        let result = try #require(converter.convertMacToWindows("/Volumes/projects/shots/seq/shot_001"))

        #expect(result.converted == "P:\\shots\\seq\\shot_001")
        #expect(result.drive == "P")
    }

    @Test("Mac reverse matching respects path boundaries")
    func macReverseMatchingRespectsPathBoundaries() {
        #expect(converter.convertMacToWindows("/Volumes/projects2/shots") == nil)
    }

    @Test("Mac single-letter volume falls back to Windows drive")
    func macSingleLetterVolumeFallsBackToWindowsDrive() throws {
        let result = try #require(converter.convertMacToWindows("/Volumes/D/cache/sim.vdb"))

        #expect(result.converted == "D:\\cache\\sim.vdb")
        #expect(result.mappingLabel == "D: -> /Volumes/D")
    }

    @Test("Detection extracts first Windows path from surrounding text")
    func detectionExtractsFirstWindowsPathFromSurroundingText() throws {
        let result = try #require(converter.detectWindowsPath(in: #"render path: "Y:\show 01\shot_020\plates""#))

        #expect(result.source == #"Y:\show 01\shot_020\plates"#)
        #expect(result.converted == "/Volumes/framestore/show 01/shot_020/plates")
    }
}
