//
//  ItemDetailView.swift
//  nudge
//
//  View and edit every field of an item; complete, pin, remind, or delete it.
//

import SwiftUI
import SwiftData
import UIKit

struct ItemDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: InboxItem
    @State private var viewModel = ItemDetailViewModel()

    // Local mirrors for the optional date toggles.
    @State private var hasReminder = false
    @State private var reminderDate = Date.now.addingTimeInterval(3600)
    @State private var hasDueDate = false
    @State private var dueDate = Date.now.addingTimeInterval(86400)
    @State private var showingDeleteConfirm = false

    var body: some View {
        Form {
            detailsSection
            if let data = item.imageData, let image = UIImage(data: data) {
                photoSection(image)
            }
            organizeSection
            datesSection
            actionsSection
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.togglePin(item, context: context)
                } label: {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                }
                .accessibilityLabel(item.isPinned ? "Unpin item" : "Pin item")
            }
        }
        .onAppear(perform: syncLocalState)
        .confirmationDialog(
            "Delete this item?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete(item, context: context)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: Sections

    private var detailsSection: some View {
        Section("Details") {
            TextField("Title", text: $item.title, axis: .vertical)
                .lineLimit(1...3)

            TextField("Notes", text: notesBinding, axis: .vertical)
                .lineLimit(2...6)

            TextField("URL", text: urlBinding)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if let url = item.sourceURL {
                Link(destination: url) {
                    Label("Open link", systemImage: "safari")
                }
            }
        }
    }

    private func photoSection(_ image: UIImage) -> some View {
        Section("Photo") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 240)
                .clipShape(.rect(cornerRadius: 12))
                .accessibilityLabel("Attached photo")
        }
    }

    private var organizeSection: some View {
        Section("Organize") {
            Picker("Category", selection: $item.type) {
                ForEach(ItemType.allCases) { type in
                    Label(type.label, systemImage: type.symbol).tag(type)
                }
            }
            Picker("Priority", selection: $item.priority) {
                ForEach(Priority.allCases) { priority in
                    Text(priority.label).tag(priority)
                }
            }
            Picker("Status", selection: $item.status) {
                ForEach(ItemStatus.allCases) { status in
                    Text(status.label).tag(status)
                }
            }
            LabeledContent("Saved", value: DateFormatting.absolute(item.createdAt))
        }
    }

    private var datesSection: some View {
        Section("Dates") {
            Toggle("Reminder", isOn: $hasReminder.animation())
            if hasReminder {
                DatePicker(
                    "Remind me",
                    selection: $reminderDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Toggle("Due date", isOn: $hasDueDate.animation())
            if hasDueDate {
                DatePicker(
                    "Due",
                    selection: $dueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
        .onChange(of: hasReminder) { _, _ in applyDates() }
        .onChange(of: reminderDate) { _, _ in applyDates() }
        .onChange(of: hasDueDate) { _, _ in applyDates() }
        .onChange(of: dueDate) { _, _ in applyDates() }
    }

    private var actionsSection: some View {
        Section {
            if item.status != .completed {
                Button {
                    viewModel.markCompleted(item, context: context)
                } label: {
                    Label("Mark as completed", systemImage: "checkmark.circle")
                }
            }

            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete item", systemImage: "trash")
            }
        }
    }

    // MARK: State sync

    private func syncLocalState() {
        hasReminder = item.reminderDate != nil
        if let r = item.reminderDate { reminderDate = r }
        hasDueDate = item.dueDate != nil
        if let d = item.dueDate { dueDate = d }
    }

    private func applyDates() {
        item.reminderDate = hasReminder ? reminderDate : nil
        item.dueDate = hasDueDate ? dueDate : nil
        try? context.save()
        viewModel.syncReminder(for: item)
    }

    // MARK: Optional-string bindings

    private var notesBinding: Binding<String> {
        Binding(
            get: { item.notes ?? "" },
            set: { item.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private var urlBinding: Binding<String> {
        Binding(
            get: { item.sourceURL?.absoluteString ?? "" },
            set: { item.sourceURL = URL(string: $0.trimmingCharacters(in: .whitespaces)) }
        )
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(item: SampleData.items()[1])
    }
    .modelContainer(SampleData.previewContainer)
}
