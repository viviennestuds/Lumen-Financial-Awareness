import Foundation
import Darwin

protocol EvidenceFileSystem {
    var temporaryDirectory: URL { get }

    func applicationSupportDirectory() throws -> URL
    func createDirectory(at url: URL) throws
    func write(_ data: Data, to url: URL, atomically: Bool) throws
    func read(_ url: URL) throws -> Data
    func fileExists(at url: URL) -> Bool
    func contentsOfDirectory(at url: URL) throws -> [URL]
    func removeItem(at url: URL) throws
    func removeDirectoryIfEmpty(at url: URL) throws
    func replaceItemAtomically(at destinationURL: URL, withItemAt sourceURL: URL) throws
    func applyCompleteFileProtection(at url: URL) throws
    func fileProtection(at url: URL) throws -> URLFileProtection?
    func clearBackupExclusion(at url: URL) throws
    func isExcludedFromBackup(at url: URL) throws -> Bool
}

struct LocalEvidenceFileSystem: EvidenceFileSystem {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    var temporaryDirectory: URL {
        fileManager.temporaryDirectory
    }

    func applicationSupportDirectory() throws -> URL {
        guard let url = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw EvidenceFileSystemError.applicationSupportUnavailable
        }
        return url
    }

    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
    }

    func write(_ data: Data, to url: URL, atomically: Bool) throws {
        try data.write(
            to: url,
            options: atomically ? [.atomic] : []
        )
    }

    func read(_ url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        guard fileExists(at: url) else {
            return []
        }
        return try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        )
    }

    func removeItem(at url: URL) throws {
        guard fileExists(at: url) else {
            return
        }
        try fileManager.removeItem(at: url)
    }

    func removeDirectoryIfEmpty(at url: URL) throws {
        guard fileExists(at: url) else {
            return
        }

        let result = url.path.withCString { path in
            Darwin.rmdir(path)
        }

        guard result == 0 else {
            let code = POSIXErrorCode(rawValue: errno) ?? .EIO
            throw POSIXError(code)
        }
    }

    func replaceItemAtomically(
        at destinationURL: URL,
        withItemAt sourceURL: URL
    ) throws {
        if fileExists(at: destinationURL) {
            _ = try fileManager.replaceItemAt(
                destinationURL,
                withItemAt: sourceURL,
                backupItemName: nil,
                options: [.usingNewMetadataOnly]
            )
        } else {
            try fileManager.moveItem(
                at: sourceURL,
                to: destinationURL
            )
        }
    }

    func applyCompleteFileProtection(at url: URL) throws {
        try (url as NSURL).setResourceValue(
            URLFileProtection.complete,
            forKey: .fileProtectionKey
        )
    }

    func fileProtection(at url: URL) throws -> URLFileProtection? {
        let values = try url.resourceValues(
            forKeys: [.fileProtectionKey]
        )
        return values.fileProtection
    }

    func clearBackupExclusion(at url: URL) throws {
        try (url as NSURL).setResourceValue(
            false,
            forKey: .isExcludedFromBackupKey
        )
    }

    func isExcludedFromBackup(at url: URL) throws -> Bool {
        let values = try url.resourceValues(
            forKeys: [.isExcludedFromBackupKey]
        )
        return values.isExcludedFromBackup ?? false
    }
}

enum EvidenceFileSystemError: Error, Equatable {
    case applicationSupportUnavailable
}
