import Testing
@testable import PathConverterCore

@Suite("Pasteboard change tracking")
struct PasteboardChangeTrackerTests {
    @Test("Initial change count does not trigger")
    func initialChangeCountDoesNotTrigger() {
        var tracker = PasteboardChangeTracker(initialChangeCount: 10)

        #expect(tracker.shouldInspect(currentChangeCount: 10) == false)
    }

    @Test("New change count triggers once")
    func newChangeCountTriggersOnce() {
        var tracker = PasteboardChangeTracker(initialChangeCount: 10)

        #expect(tracker.shouldInspect(currentChangeCount: 11) == true)
        #expect(tracker.shouldInspect(currentChangeCount: 11) == false)
    }

    @Test("Own pasteboard write can be acknowledged without triggering")
    func ownPasteboardWriteCanBeAcknowledgedWithoutTriggering() {
        var tracker = PasteboardChangeTracker(initialChangeCount: 10)

        tracker.acknowledge(currentChangeCount: 12)

        #expect(tracker.shouldInspect(currentChangeCount: 12) == false)
        #expect(tracker.shouldInspect(currentChangeCount: 13) == true)
    }
}
