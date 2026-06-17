import Foundation

public enum ConversionDirection: Equatable, Sendable {
    case windowsToMac
    case macPrompt
    case macToWindows
}

public struct ConversionResult: Equatable, Sendable {
    public var source: String
    public var converted: String?
    public var direction: ConversionDirection
    public var drive: String
    public var mappingLabel: String

    public init(
        source: String,
        converted: String?,
        direction: ConversionDirection,
        drive: String,
        mappingLabel: String
    ) {
        self.source = source
        self.converted = converted
        self.direction = direction
        self.drive = drive
        self.mappingLabel = mappingLabel
    }
}

public struct PathConverter: Sendable {
    public var mappings: [PathMapping]

    public init(mappings: [PathMapping]) {
        self.mappings = mappings
    }

    public func detectWindowsPath(in text: String) -> ConversionResult? {
        guard let candidate = firstWindowsPath(in: text) else { return nil }
        return convertWindowsToMac(candidate)
    }

    public func convertWindowsToMac(_ rawPath: String) -> ConversionResult? {
        let source = cleanPath(rawPath)
        guard let parsed = parseWindowsPath(source) else { return nil }
        let mapping = mappingForWindowsDrive(parsed.drive)
        let macPrefix = mapping?.mac ?? "/Volumes/\(parsed.drive)"

        guard !macPrefix.isEmpty else { return nil }

        let suffix = parsed.remainder
            .replacingOccurrences(of: "\\", with: "/")
            .trimmingLeadingSlashes()
        let converted = suffix.isEmpty
            ? macPrefix
            : "\(macPrefix)/\(suffix)"

        return ConversionResult(
            source: source,
            converted: converted,
            direction: .windowsToMac,
            drive: parsed.drive,
            mappingLabel: "\(parsed.drive): -> \(macPrefix)"
        )
    }

    public func detectMacPathPrompt(_ rawPath: String) -> ConversionResult? {
        let source = cleanPath(rawPath)
        guard let match = bestMacMappingMatch(for: source) else { return nil }

        return ConversionResult(
            source: source,
            converted: nil,
            direction: .macPrompt,
            drive: match.drive,
            mappingLabel: "\(match.drive): -> \(match.macPrefix)"
        )
    }

    public func convertMacToWindows(_ rawPath: String) -> ConversionResult? {
        let source = cleanPath(rawPath)
        guard let match = bestMacMappingMatch(for: source) else { return nil }

        let suffix = source.dropFirst(match.macPrefix.count)
            .description
            .trimmingLeadingSlashes()
            .replacingOccurrences(of: "/", with: "\\")
        let converted = suffix.isEmpty
            ? "\(match.drive):\\"
            : "\(match.drive):\\\(suffix)"

        return ConversionResult(
            source: source,
            converted: converted,
            direction: .macToWindows,
            drive: match.drive,
            mappingLabel: "\(match.drive): -> \(match.macPrefix)"
        )
    }

    private func mappingForWindowsDrive(_ drive: String) -> PathMapping? {
        mappings.first { $0.win == drive }
    }

    private func parseWindowsPath(_ path: String) -> (drive: String, remainder: String)? {
        guard path.count >= 2 else { return nil }
        let drive = String(path.prefix(1)).uppercased()
        guard drive.range(of: #"^[A-Z]$"#, options: .regularExpression) != nil else { return nil }
        let colonIndex = path.index(after: path.startIndex)
        guard path[colonIndex] == ":" else { return nil }
        let remainderStart = path.index(after: colonIndex)
        let remainder = remainderStart < path.endIndex ? String(path[remainderStart...]) : ""
        guard remainder.isEmpty || remainder.first == "\\" || remainder.first == "/" else { return nil }
        return (drive, remainder)
    }

    private func firstWindowsPath(in text: String) -> String? {
        let cleaned = cleanPath(text)
        if parseWindowsPath(cleaned) != nil {
            return cleaned
        }

        let pattern = #"(?i)[A-Z]:[\\/][^\n\r"]+"#
        guard let range = cleaned.range(of: pattern, options: .regularExpression) else { return nil }
        return String(cleaned[range]).trimmedPathPunctuation()
    }

    private func bestMacMappingMatch(for source: String) -> (drive: String, macPrefix: String)? {
        let configuredMatches = mappings
            .filter { !$0.mac.isEmpty }
            .compactMap { mapping -> (drive: String, macPrefix: String)? in
                let prefix = PathMapping.normalizeMacPrefix(mapping.mac)
                guard source.hasPathPrefix(prefix) else { return nil }
                return (mapping.win, prefix)
            }
            .sorted { $0.macPrefix.count > $1.macPrefix.count }

        if let configuredMatch = configuredMatches.first {
            return configuredMatch
        }

        let components = source.split(separator: "/", omittingEmptySubsequences: true)
        guard components.count >= 2,
              components[0] == "Volumes",
              components[1].count == 1,
              let letter = components[1].first,
              letter.isLetter
        else {
            return nil
        }

        let drive = String(letter).uppercased()
        return (drive, "/Volumes/\(drive)")
    }

    private func cleanPath(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingMatchingQuotes()
    }
}

private extension String {
    func trimmingLeadingSlashes() -> String {
        String(drop(while: { $0 == "/" || $0 == "\\" }))
    }

    func trimmingTrailingSlashes() -> String {
        var value = self
        while value.count > 1, value.last == "/" {
            value.removeLast()
        }
        return value
    }

    func trimmingMatchingQuotes() -> String {
        guard count >= 2 else { return self }
        let pairs: [(Character, Character)] = [("\"", "\""), ("'", "'"), ("“", "”"), ("‘", "’")]
        for pair in pairs where first == pair.0 && last == pair.1 {
            return String(dropFirst().dropLast())
        }
        return self
    }

    func trimmedPathPunctuation() -> String {
        trimmingCharacters(in: CharacterSet(charactersIn: " \t\r\n\"'“”‘’<>"))
    }

    func hasPathPrefix(_ prefix: String) -> Bool {
        self == prefix || hasPrefix(prefix + "/")
    }
}
