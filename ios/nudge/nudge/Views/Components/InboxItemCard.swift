//
//  InboxItemCard.swift
//  nudge
//
//  The card used to represent an InboxItem in lists.
//

import SwiftUI
import UIKit

struct InboxItemCard: View {
    let item: InboxItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            typeIcon

            VStack(alignment: .leading, spacing: 6) {
                titleRow
                if let host = item.sourceHost {
                    sourcePreview(host: host)
                }
                metadataRow
            }

            Spacer(minLength: 0)

            thumbnail
        }
        .padding(14)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Pieces

    private var typeIcon: some View {
        Image(systemName: item.type.symbol)
            .font(.headline)
            .foregroundStyle(item.type.tint)
            .frame(width: 36, height: 36)
            .background(item.type.tint.opacity(0.15), in: .rect(cornerRadius: 10))
            .accessibilityHidden(true)
    }

    private var titleRow: some View {
        HStack(spacing: 6) {
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)
            }
            Text(item.title)
                .font(.body.weight(.medium))
                .lineLimit(2)
        }
    }

    private func sourcePreview(host: String) -> some View {
        Label(host, systemImage: "link")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            if item.priority == .high {
                Label("High", systemImage: item.priority.symbol)
                    .labelStyle(.iconOnly)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(item.priority.tint)
            }

            if let date = item.effectiveDate {
                Label(DateFormatting.relative(date), systemImage: dateSymbol)
                    .font(.caption)
                    .foregroundStyle(dateColor(for: date))
            }

            if let location = item.locationName {
                Label(location, systemImage: "mappin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = item.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(.rect(cornerRadius: 10))
                .accessibilityHidden(true)
        }
    }

    // MARK: Helpers

    private var dateSymbol: String {
        item.reminderDate != nil ? "bell" : "calendar"
    }

    private func dateColor(for date: Date) -> Color {
        date < .now ? .red : .secondary
    }

    private var accessibilityLabel: String {
        var parts = ["\(item.type.label): \(item.title)"]
        if item.isPinned { parts.append("Pinned") }
        if item.priority == .high { parts.append("High priority") }
        if let date = item.effectiveDate {
            parts.append("Due \(DateFormatting.relative(date))")
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(SampleData.items()) { item in
                InboxItemCard(item: item)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
