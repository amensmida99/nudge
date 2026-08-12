//
//  APIClient.swift
//  nudge
//
//  Networking abstraction. A future AWS backend can implement `APIClient`
//  without any change to the UI or view models.
//

import Foundation

/// Data transfer object representing an item on a remote backend.
///
/// Kept separate from the SwiftData `InboxItem` so the persistence model and the
/// wire format can evolve independently.
struct RemoteItemDTO: Codable, Identifiable {
    let id: UUID
    var title: String
    var sourceURL: URL?
    var notes: String?
    var type: ItemType
    var status: ItemStatus
    var createdAt: Date
    var dueDate: Date?
    var reminderDate: Date?
    var priority: Priority
    var aiSummary: String?
    var isPinned: Bool
}

/// The contract every backend (mock or real) must satisfy.
///
/// All methods are async so callers use `await`, and remain identical whether the
/// implementation talks to the network or returns canned data.
protocol APIClient: Sendable {
    /// Fetch the latest items from the backend.
    func fetchItems() async throws -> [RemoteItemDTO]

    /// Push a locally-created/updated item to the backend.
    func syncItem(_ item: RemoteItemDTO) async throws

    /// Delete an item on the backend.
    func deleteItem(id: UUID) async throws

    /// Ask the backend to produce a richer AI summary for a piece of content.
    /// The mock returns a deterministic string so the UI has something to show.
    func generateSummary(for text: String) async throws -> String
}

/// In-memory mock used until the real backend exists.
///
/// Simulates latency and echoes back data so flows can be exercised end to end.
final class MockAPIClient: APIClient {

    /// Simulated network delay in nanoseconds.
    private let latency: UInt64

    init(latencyMilliseconds: UInt64 = 250) {
        self.latency = latencyMilliseconds * 1_000_000
    }

    func fetchItems() async throws -> [RemoteItemDTO] {
        try await Task.sleep(nanoseconds: latency)
        // A real client would decode a network response here.
        return []
    }

    func syncItem(_ item: RemoteItemDTO) async throws {
        try await Task.sleep(nanoseconds: latency)
        // No-op: pretend the item was accepted by the server.
    }

    func deleteItem(id: UUID) async throws {
        try await Task.sleep(nanoseconds: latency)
        // No-op.
    }

    func generateSummary(for text: String) async throws -> String {
        try await Task.sleep(nanoseconds: latency)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let snippet = trimmed.prefix(80)
        return "Summary: \(snippet)\(trimmed.count > 80 ? "…" : "")"
    }
}
