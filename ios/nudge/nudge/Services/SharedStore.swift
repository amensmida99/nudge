//
//  SharedStore.swift
//  nudge
//
//  Reads/writes pending captures in the shared App Group container.
//

import Foundation

/// Bridges the Share Extension and the main app through the App Group container.
///
/// The extension appends `PendingSharedItem`s; the main app drains them on launch/
/// foreground and converts them into `InboxItem`s. Access is guarded by a lock so
/// concurrent writes from the two processes don't corrupt the queue.
///
/// This type must be usable from BOTH targets, so add it to the Share Extension's
/// target membership in Xcode (see `SETUP.md`).
struct SharedStore {

    private static let pendingKey = "pendingSharedItems"

    /// The shared defaults suite. Falls back to `.standard` if the App Group is
    /// unavailable (e.g. entitlement not configured) so the app still runs.
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
    }

    /// Serializes access across the two processes as much as UserDefaults allows.
    private static let lock = NSLock()

    // MARK: Writing (used primarily by the Share Extension)

    /// Appends a pending item to the shared queue.
    static func enqueue(_ item: PendingSharedItem) {
        lock.lock()
        defer { lock.unlock() }

        var current = loadPending_locked()
        current.append(item)
        savePending_locked(current)
    }

    // MARK: Reading / draining (used by the main app)

    /// Returns all pending items without removing them.
    static func loadPending() -> [PendingSharedItem] {
        lock.lock()
        defer { lock.unlock() }
        return loadPending_locked()
    }

    /// Atomically returns and clears the pending queue so imports happen once.
    static func drainPending() -> [PendingSharedItem] {
        lock.lock()
        defer { lock.unlock() }

        let items = loadPending_locked()
        defaults.removeObject(forKey: pendingKey)
        return items
    }

    // MARK: Private (must hold `lock`)

    private static func loadPending_locked() -> [PendingSharedItem] {
        guard let data = defaults.data(forKey: pendingKey) else { return [] }
        return (try? JSONDecoder().decode([PendingSharedItem].self, from: data)) ?? []
    }

    private static func savePending_locked(_ items: [PendingSharedItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: pendingKey)
    }
}
