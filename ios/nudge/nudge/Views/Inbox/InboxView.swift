//
//  InboxView.swift
//  nudge
//
//  All active saved items with search, category/status filters, and sorting.
//

import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env

    @Query(sort: \InboxItem.createdAt, order: .reverse) private var allItems: [InboxItem]

    @State private var viewModel = InboxViewModel()
    @State private var showingAddItem = false
    @State private var selectedItem: InboxItem?

    private var items: [InboxItem] { viewModel.visibleItems(from: allItems) }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Inbox")
            .searchable(text: $viewModel.searchText, prompt: "Search items")
            .toolbar { toolbarContent }
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
            .refreshable {
                await viewModel.refresh(using: env.apiClient)
            }
        }
    }

    // MARK: List

    private var list: some View {
        List {
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
        .listStyle(.plain)
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: viewModel.isFiltering ? "line.3.horizontal.decrease.circle" : "tray",
            title: viewModel.isFiltering ? "No matches" : "Your inbox is empty",
            message: viewModel.isFiltering
                ? "Try adjusting your search or filters."
                : "Save links, notes, and photos and they'll collect here.",
            actionTitle: viewModel.isFiltering ? nil : "Add an item",
            action: viewModel.isFiltering ? nil : { showingAddItem = true }
        )
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showingAddItem = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add item")
        }

        ToolbarItem(placement: .topBarLeading) {
            Menu {
                sortMenu
                Divider()
                categoryMenu
                Divider()
                statusMenu
            } label: {
                Image(systemName: viewModel.isFiltering
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel("Filter and sort")
        }
    }

    private var sortMenu: some View {
        Picker("Sort", selection: $viewModel.sort) {
            ForEach(InboxSort.allCases) { option in
                Text(option.label).tag(option)
            }
        }
    }

    private var categoryMenu: some View {
        Menu("Category") {
            Button { viewModel.typeFilter = nil } label: {
                Label("All", systemImage: viewModel.typeFilter == nil ? "checkmark" : "")
            }
            ForEach(ItemType.allCases) { type in
                Button {
                    viewModel.typeFilter = type
                } label: {
                    Label(type.label, systemImage: viewModel.typeFilter == type ? "checkmark" : type.symbol)
                }
            }
        }
    }

    private var statusMenu: some View {
        Menu("Status") {
            Button { viewModel.statusFilter = nil } label: {
                Label("Active", systemImage: viewModel.statusFilter == nil ? "checkmark" : "")
            }
            ForEach(ItemStatus.allCases) { status in
                Button {
                    viewModel.statusFilter = status
                } label: {
                    Label(status.label, systemImage: viewModel.statusFilter == status ? "checkmark" : "")
                }
            }
        }
    }
}

#Preview {
    InboxView()
        .modelContainer(SampleData.previewContainer)
}
