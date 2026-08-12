//
//  ShareViewController.swift
//  NudgeShareExtension
//
//  Receives text, URLs, and images from the iOS Share Sheet and stores them as
//  a PendingSharedItem in the shared App Group container for the main app.
//
//  ─────────────────────────────────────────────────────────────────────────
//  IMPORTANT — this file belongs to the SHARE EXTENSION target, NOT the app.
//  See SETUP.md at the repo root for how to create the target and wire it up.
//  ─────────────────────────────────────────────────────────────────────────
//
//  Files this target must ALSO include (add them to the extension's target
//  membership in Xcode — right side "Target Membership" checkbox):
//    • Models/PendingSharedItem.swift
//    • Services/SharedStore.swift
//    • Utilities/AppConstants.swift   (for the App Group ID)
//    • Models/Enums.swift             (for ItemType used by classification)
//

import UIKit
import UniformTypeIdentifiers
import Social

/// A minimal, code-only share extension. We use a plain UIViewController rather
/// than SLComposeServiceViewController so we can process multiple attachment
/// types and finish quickly without a compose UI.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Task { await handleSharedContent() }
    }

    /// Walks every attachment on the extension's input items, converts the first
    /// recognizable piece of content into a `PendingSharedItem`, and enqueues it.
    private func handleSharedContent() async {
        guard
            let extensionItems = extensionContext?.inputItems as? [NSExtensionItem]
        else {
            complete()
            return
        }

        var title: String?
        var urlString: String?
        var notes: String?
        var imageData: Data?

        for extensionItem in extensionItems {
            // The share sheet often provides a content text (e.g. tweet body).
            if let text = extensionItem.attributedContentText?.string, !text.isEmpty {
                notes = text
            }

            for provider in extensionItem.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await loadItem(provider, type: UTType.url) as? URL {
                        urlString = url.absoluteString
                        title = title ?? url.host()
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    imageData = await loadImageData(provider)
                    title = title ?? "Shared image"
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await loadItem(provider, type: UTType.plainText) as? String {
                        title = title ?? String(text.prefix(80))
                        notes = notes ?? text
                    }
                }
            }
        }

        // Build a sensible title if we only had a URL/notes.
        let finalTitle = title
            ?? notes.map { String($0.prefix(80)) }
            ?? "Saved item"

        let guessedType = classify(title: finalTitle, urlString: urlString)

        let pending = PendingSharedItem(
            title: finalTitle,
            urlString: urlString,
            notes: notes,
            typeRaw: guessedType.rawValue,
            imageData: imageData
        )
        SharedStore.enqueue(pending)

        complete()
    }

    // MARK: Attachment loading helpers

    private func loadItem(_ provider: NSItemProvider, type: UTType) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { item, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: item) }
            }
        }
    }

    /// Loads image data whether the provider vends a UIImage, URL, or Data.
    private func loadImageData(_ provider: NSItemProvider) async -> Data? {
        guard let item = try? await loadItem(provider, type: UTType.image) else { return nil }
        switch item {
        case let url as URL:
            return try? Data(contentsOf: url)
        case let image as UIImage:
            return image.jpegData(compressionQuality: 0.8)
        case let data as Data:
            return data
        default:
            return nil
        }
    }

    /// A tiny inline classifier so the extension can tag content without pulling
    /// in the full app. Mirrors the app's keyword approach at a smaller scale.
    private func classify(title: String, urlString: String?) -> ItemType {
        let text = "\(title) \(urlString ?? "")".lowercased()
        if text.contains("youtube") || text.contains("netflix") { return .watch }
        if text.contains("amazon") || text.contains("shop") { return .buy }
        if urlString != nil { return .read }
        return .other
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
