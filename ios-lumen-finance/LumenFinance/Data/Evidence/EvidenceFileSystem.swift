import Foundation
import Darwin

enum EvidenceFileNodeKind: Equatable {
    case missing
    case regularFile
    case directory
    case symbolicLink
    case other
}

protocol EvidenceFileSystem {
    var temporaryDirectory: URL { get }

    func applicationSupportDirectory() throws -> URL
    func nodeKind(at url: URL) throws -> EvidenceFileNodeKind
    func createDirectory(at url: URL) throws
    func write(_ data: Data, to url: URL, atomically: Bool) throws
    func read(_ url: URL) throws -> Data
    func contentsOfDirectory(at url: URL) throws -> [URL]
    func removeRegularFile(at url: URL) throws
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

        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )

        let kind = try nodeKind(at: url)
        guard kind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(url, kind)
        }

        return url
    }

    func nodeKind(at url: URL) throws -> EvidenceFileNodeKind {
        var information = stat()
        let result = url.path.withCString { path in
            Darwin.lstat(path, &information)
        }

        if result == 0 {
            switch information.st_mode & S_IFMT {
            case S_IFREG:
                return .regularFile
            case S_IFDIR:
                return .directory
            case S_IFLNK:
                return .symbolicLink
            default:
                return .other
            }
        }

        if errno == ENOENT {
            return .missing
        }

        let code = POSIXErrorCode(rawValue: errno) ?? .EIO
        throw POSIXError(code)
    }

    func createDirectory(at url: URL) throws {
        let existingKind = try nodeKind(at: url)

        if existingKind == .directory {
            return
        }

        guard existingKind == .missing else {
            throw EvidenceFileSystemError.expectedDirectory(
                url,
                existingKind
            )
        }

        let parent = url.deletingLastPathComponent()
        let parentKind = try nodeKind(at: parent)
        guard parentKind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(
                parent,
                parentKind
            )
        }

        try fileManager.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )

        let createdKind = try nodeKind(at: url)
        guard createdKind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(
                url,
                createdKind
            )
        }
    }

    func write(_ data: Data, to url: URL, atomically: Bool) throws {
        let parent = url.deletingLastPathComponent()
        let parentKind = try nodeKind(at: parent)
        guard parentKind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(parent, parentKind)
        }

        let existingKind = try nodeKind(at: url)
        guard existingKind == .missing || existingKind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(url, existingKind)
        }

        try data.write(
            to: url,
            options: atomically ? [.atomic] : []
        )

        let writtenKind = try nodeKind(at: url)
        guard writtenKind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(url, writtenKind)
        }
    }

    func read(_ url: URL) throws -> Data {
        let kind = try nodeKind(at: url)
        guard kind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(url, kind)
        }
        return try Data(contentsOf: url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        let kind = try nodeKind(at: url)
        guard kind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(url, kind)
        }

        return try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        )
    }

    func removeRegularFile(at url: URL) throws {
        let kind = try nodeKind(at: url)

        if kind == .missing {
            return
        }

        guard kind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(url, kind)
        }

        let result = url.path.withCString { path in
            Darwin.unlink(path)
        }

        guard result == 0 else {
            let code = POSIXErrorCode(rawValue: errno) ?? .EIO
            throw POSIXError(code)
        }
    }

    func removeDirectoryIfEmpty(at url: URL) throws {
        let kind = try nodeKind(at: url)

        if kind == .missing {
            return
        }

        guard kind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(url, kind)
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
        let sourceKind = try nodeKind(at: sourceURL)
        guard sourceKind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(
                sourceURL,
                sourceKind
            )
        }

        let sourceParent = sourceURL.deletingLastPathComponent()
        let destinationParent = destinationURL.deletingLastPathComponent()

        let sourceParentKind = try nodeKind(at: sourceParent)
        guard sourceParentKind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(
                sourceParent,
                sourceParentKind
            )
        }

        let destinationParentKind = try nodeKind(at: destinationParent)
        guard destinationParentKind == .directory else {
            throw EvidenceFileSystemError.expectedDirectory(
                destinationParent,
                destinationParentKind
            )
        }

        let destinationKind = try nodeKind(at: destinationURL)
        guard destinationKind == .missing || destinationKind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(
                destinationURL,
                destinationKind
            )
        }

        if destinationKind == .regularFile {
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

        let finalKind = try nodeKind(at: destinationURL)
        guard finalKind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(
                destinationURL,
                finalKind
            )
        }
    }

    func applyCompleteFileProtection(at url: URL) throws {
        try requireRegularFile(at: url)
        try (url as NSURL).setResourceValue(
            URLFileProtection.complete,
            forKey: .fileProtectionKey
        )
    }

    func fileProtection(at url: URL) throws -> URLFileProtection? {
        try requireRegularFile(at: url)

        let freshURL = URL(
            fileURLWithPath: url.path,
            isDirectory: false
        )
        let values = try freshURL.resourceValues(
            forKeys: [.fileProtectionKey]
        )
        return values.fileProtection
    }

    func clearBackupExclusion(at url: URL) throws {
        try requireRegularFile(at: url)
        try (url as NSURL).setResourceValue(
            false,
            forKey: .isExcludedFromBackupKey
        )
    }

    func isExcludedFromBackup(at url: URL) throws -> Bool {
        try requireRegularFile(at: url)

        let freshURL = URL(
            fileURLWithPath: url.path,
            isDirectory: false
        )
        let values = try freshURL.resourceValues(
            forKeys: [.isExcludedFromBackupKey]
        )
        return values.isExcludedFromBackup ?? false
    }

    private func requireRegularFile(at url: URL) throws {
        let kind = try nodeKind(at: url)
        guard kind == .regularFile else {
            throw EvidenceFileSystemError.expectedRegularFile(url, kind)
        }
    }
}

enum EvidenceFileSystemError: Error, Equatable {
    case applicationSupportUnavailable
    case expectedDirectory(URL, EvidenceFileNodeKind)
    case expectedRegularFile(URL, EvidenceFileNodeKind)
}
