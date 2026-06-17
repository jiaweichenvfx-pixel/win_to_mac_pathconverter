public struct PasteboardChangeTracker: Equatable, Sendable {
    private var lastChangeCount: Int

    public init(initialChangeCount: Int) {
        self.lastChangeCount = initialChangeCount
    }

    public mutating func shouldInspect(currentChangeCount: Int) -> Bool {
        guard currentChangeCount != lastChangeCount else { return false }
        lastChangeCount = currentChangeCount
        return true
    }

    public mutating func acknowledge(currentChangeCount: Int) {
        lastChangeCount = currentChangeCount
    }
}
