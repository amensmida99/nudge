//
//  ForgottenView.swift
//  nudge
//
//  Resurfaces items saved over a week ago that still need action.
//

import SwiftUI
import SwiftData

struct ForgottenView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \InboxItem.createdAt, order: .reverse) private var allItems: [InboxItem]

    @State private var viewModel = ForgottenViewModel()
    @State private var selectedItem: InboxItem?

    private var items: [InboxItem] { viewModel.forgottenItems(from: allItems) }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(
                        symbol: "sparkles",
                        title: "Nothing forgotten",
                        message: "You've kept up with everything you saved this week. Nice."
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Forgotten")
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
        }
    }

    private var list: some View {
        List {
            Section {
                summaryCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        InboxItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            ItemMutator.complete(item, context: context)
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(.green)
                        Button {
                            ItemMutator.archive(item, context: context)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.gray)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.summary(for: allItems))
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button {
                    viewModel.snoozeAll(allItems, context: context)
                } label: {
                    Label("Snooze all", systemImage: "clock")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.reviewLater(allItems, context: context)
                } label: {
                    Label("Review later", systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
    }
}

#Preview {
    ForgottenView()
        .modelContainer(SampleData.previewContainer)
}
