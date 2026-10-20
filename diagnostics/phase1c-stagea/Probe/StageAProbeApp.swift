import Foundation
import SwiftUI
import Darwin

private enum ProbeRole: String {
    case waiting = "a0-wait"
    case injectedError = "a0-injected-error"
    case ordinaryExit = "a0-ordinary-exit"
    case create = "a1-create"
    case observe = "a1-observer"
    case observeMissing = "a4-missing-observer"
}

private enum ProbeInputError: Error {
    case invalidArguments
    case unsafeLocation
    case unsupportedRole
    case injected
    case missingHostAcknowledgement
}

private struct ProbeInvocation {
    let role: ProbeRole
    let runID: String
    let launchID: String
    let root: URL

    static func parse(_ args: [String]) throws -> ProbeInvocation {
        guard args.count == 9 else { throw ProbeInputError.invalidArguments }
        var values: [String: String] = [:]
        var index = 1
        while index < args.count {
            let key = args[index]
            guard ["--role", "--run-id", "--launch-id", "--root"].contains(key),
                  values[key] == nil else { throw ProbeInputError.invalidArguments }
            values[key] = args[index + 1]
            index += 2
        }
        guard let roleName = values["--role"],
              let role = ProbeRole(rawValue: roleName),
              let runID = values["--run-id"],
              let uuid = UUID(uuidString: runID),
              uuid.uuidString.lowercased() == runID.lowercased(),
              let launchID = values["--launch-id"],
              let launchUUID = UUID(uuidString: launchID),
              launchUUID.uuidString.lowercased() == launchID.lowercased(),
              let rootValue = values["--root"], rootValue.hasPrefix("/") else {
            throw ProbeInputError.invalidArguments
        }
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false
        )
        let expected = support.appendingPathComponent("Phase1CStageA", isDirectory: true)
            .appendingPathComponent(runID, isDirectory: true).standardizedFileURL
        let supplied = URL(fileURLWithPath: rootValue, isDirectory: true).standardizedFileURL
        guard expected.path == supplied.path,
              expected.resolvingSymlinksInPath().path == supplied.resolvingSymlinksInPath().path else {
            throw ProbeInputError.unsafeLocation
        }
        return ProbeInvocation(role: role, runID: runID, launchID: launchID, root: supplied)
    }

    var events: URL { root.appendingPathComponent("events", isDirectory: true) }

    func waitForHostIdentityAcknowledgement() async throws {
        // Unique per process launch; a previous worker acknowledgement cannot
        // release a fresh observer that shares the same diagnostic run directory.
        let acknowledgement = events.appendingPathComponent("host_ack_\(launchID).txt")
        for _ in 0..<200 {
            if let data = try? Data(contentsOf: acknowledgement),
               let contents = String(data: data, encoding: .utf8) {
                guard contents == launchID + "\n" else {
                    throw ProbeInputError.missingHostAcknowledgement
                }
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        throw ProbeInputError.missingHostAcknowledgement
    }

    func mark(_ name: String, value: String) throws {
        guard name.range(of: "^[a-z0-9_-]+$", options: .regularExpression) != nil else {
            throw ProbeInputError.invalidArguments
        }
        try FileManager.default.createDirectory(at: events, withIntermediateDirectories: true)
        let file = events.appendingPathComponent(name + ".txt")
        try Data(value.utf8).write(to: file, options: [.atomic])
    }
}

@main
struct StageAProbeApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Disposable Stage A diagnostic — synthetic data only")
                .task { await run() }
        }
    }

    @MainActor
    private func run() async {
        do {
            let request = try ProbeInvocation.parse(ProcessInfo.processInfo.arguments)
            try request.mark("role_\(request.launchID)", value: request.role.rawValue + "\n" + request.runID)
            // Host authentication is a prerequisite for *any* diagnostic operation,
            // not merely a gate for process exit. The role marker is the only
            // launch handshake produced before the matching acknowledgment.
            try await request.waitForHostIdentityAcknowledgement()
            switch request.role {
            case .waiting:
                try request.mark("waiting", value: "waiting for external controller\n")
                while true { try await Task.sleep(nanoseconds: 2_000_000_000) }
            case .injectedError:
                try request.mark("negative_injected", value: "deliberate Swift-side error\n")
                throw ProbeInputError.injected
            case .ordinaryExit:
                try request.mark("negative_ordinary", value: "ordinary exit\n")
                exit(EXIT_SUCCESS)
            case .create:
                try StageAStoreDriver.createAndSave(
                    root: request.root, runID: request.runID,
                    mark: { try request.mark($0, value: $1) }
                )
                exit(EXIT_SUCCESS)
            case .observe, .observeMissing:
                try StageAObserver.inspect(
                    root: request.root, runID: request.runID,
                    expectMissing: request.role == .observeMissing,
                    mark: { try request.mark($0, value: $1) }
                )
                exit(EXIT_SUCCESS)
            }
        } catch {
            // The operator must rely on independent controller observations, not only this marker.
            // Avoid printing private paths or injecting error descriptions into shared logs.
            exit(65)
        }
    }
}
