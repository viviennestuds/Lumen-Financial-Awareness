import Foundation
import SwiftData

enum StageAStoreDriver {
    static func storeURL(in directory: URL) -> URL {
        directory.appendingPathComponent("diagnostic.store", isDirectory: false)
    }

    @MainActor
    static func container(at url: URL) throws -> ModelContainer {
        let schema = Schema([StageASentinel.self])
        let config = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(for: schema, configurations: [config])
        container.mainContext.autosaveEnabled = false
        return container
    }

    @MainActor
    static func createAndSave(
        root: URL, runID: String,
        mark: (String, String) throws -> Void
    ) throws {
        let sourceDirectory = root.appendingPathComponent("source-store", isDirectory: true)
        let copyDirectory = root.appendingPathComponent("inspection-copy", isDirectory: true)
        guard !FileManager.default.fileExists(atPath: copyDirectory.path),
              !FileManager.default.fileExists(atPath: sourceDirectory.path) else {
            throw StoreError.unexpectedExistingStore
        }
        try FileManager.default.createDirectory(
            at: sourceDirectory, withIntermediateDirectories: true
        )
        let url = storeURL(in: sourceDirectory)
        try mark("store_before_open", "configured store: diagnostic.store\n")
        let container = try container(at: url)
        try mark("store_open_returned", "container initialized\n")
        let context = container.mainContext
        context.insert(StageASentinel(runID: runID, token: StageASentinel.fixedToken))
        try mark("store_before_save", "synthetic insert pending\n")
        try context.save()
        try mark("store_save_returned", "save returned; not crash-durability proof\n")
        // This exit is deliberate, not A2/A3 process-termination characterization.
        withExtendedLifetime(container) {}
    }

    enum StoreError: Error { case unexpectedExistingStore }
}
