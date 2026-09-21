import Foundation

actor EvidenceOperationCoordinator {
    static let shared = EvidenceOperationCoordinator()

    struct Lease: Sendable {
        let sourceID: UUID
        fileprivate let token: UInt64
    }

    private var holders: [UUID: UInt64] = [:]
    private var waiters: [UUID: [CheckedContinuation<Lease, Never>]] = [:]
    private var nextToken: UInt64 = 0

    func acquire(for sourceID: UUID) async -> Lease {
        if holders[sourceID] == nil {
            return makeLease(for: sourceID)
        }

        return await withCheckedContinuation { continuation in
            waiters[sourceID, default: []].append(continuation)
        }
    }

    func release(_ lease: Lease) {
        guard holders[lease.sourceID] == lease.token else {
            return
        }

        if var sourceWaiters = waiters[lease.sourceID],
           !sourceWaiters.isEmpty {
            let next = sourceWaiters.removeFirst()

            if sourceWaiters.isEmpty {
                waiters.removeValue(forKey: lease.sourceID)
            } else {
                waiters[lease.sourceID] = sourceWaiters
            }

            next.resume(returning: makeLease(for: lease.sourceID))
            return
        }

        holders.removeValue(forKey: lease.sourceID)
    }

    private func makeLease(for sourceID: UUID) -> Lease {
        nextToken &+= 1
        let lease = Lease(
            sourceID: sourceID,
            token: nextToken
        )
        holders[sourceID] = lease.token
        return lease
    }
}
