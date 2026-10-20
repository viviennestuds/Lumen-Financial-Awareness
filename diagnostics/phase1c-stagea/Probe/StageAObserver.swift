import Foundation
import SwiftData
import Darwin

enum StageAObserver {
    enum ObservationError: Error {
        case missingCopyRoot
        case sourceAndCopyNotDisjoint
        case unexpectedCopyStore
        case unexpectedSentinel
        case missingSentinel
    }

    @MainActor
    static func inspect(
        root: URL, runID: String, expectMissing: Bool,
        mark: (String, String) throws -> Void
    ) throws {
        let source = root.appendingPathComponent("source-store", isDirectory: true)
        let copy = root.appendingPathComponent("inspection-copy", isDirectory: true)
        guard copy.standardizedFileURL.path != source.standardizedFileURL.path,
              copy.resolvingSymlinksInPath().path != source.resolvingSymlinksInPath().path else {
            throw ObservationError.sourceAndCopyNotDisjoint
        }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: copy.path, isDirectory: &isDir),
              isDir.boolValue else { throw ObservationError.missingCopyRoot }

        // The host has already captured and validated the full pre-open source/copy
        // inventories. This marker is not permission to claim observer neutrality.
        let url = StageAStoreDriver.storeURL(in: copy)
        let wasPresent = FileManager.default.fileExists(atPath: url.path)
        if expectMissing && wasPresent { throw ObservationError.unexpectedCopyStore }
        if !expectMissing && !wasPresent { throw ObservationError.missingSentinel }
        try mark("observer_before_open",
                 "copy-store pre-open exists=\(wasPresent); source not opened\n")

        let container = try StageAStoreDriver.container(at: url)
        let records = try container.mainContext.fetch(FetchDescriptor<StageASentinel>())
        if expectMissing {
            guard records.isEmpty else { throw ObservationError.unexpectedSentinel }
        } else {
            guard records.count == 1,
                  records[0].runID == runID,
                  records[0].token == StageASentinel.fixedToken else {
                throw ObservationError.unexpectedSentinel
            }
        }
        try mark("observer_fetch",
                 "synthetic record count=\(records.count); confined to copy\n")
        withExtendedLifetime(container) {}
    }
}
