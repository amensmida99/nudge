//
//  TodayView.swift
//  nudge
//
//  "What should I deal with now?" — the prioritized daily list.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context

    /// All items; ranking/filtering happens in the view model.
    @Query(sort: \InboxItem.createdAt, order: .reverse) private var allItems: [InboxItem]

    @State private var viewModel = TodayViewModel()
    @State private var showingAddItem = false
    @State private var selectedItem: InboxItem?

    private var items: [InboxItem] { viewModel.todayItems(from: allItems) }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    EmptyStateView(
                        symbol: "checkmark.circle",
                        title: "You're clear for now",
                        message: "Nothing needs your attention right now. Save something and Nudge will resurface it when it matters.",
                        actionTitle: "Add an item",
                        action: { showingAddItem = true }
                    )
                } else {
                    list
                }
            }
            .navigationTitle("What should I\ndeal with now?")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add item")
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
        }
    }

    private var list: some View {
        List {
            Section {
                Text(viewModel.subtitle(for: items.count))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
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
                            viewModel.complete(item, context: context)
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(.green)

                        Button {
                            viewModel.archive(item, context: context)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.gray)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            viewModel.snooze(item, context: context)
                        } label: {
                            Label("Snooze", systemImage: "clock")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    TodayView()
        .modelContainer(SampleData.previewContainer)
}
