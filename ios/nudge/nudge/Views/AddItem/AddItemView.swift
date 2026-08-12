//
//  AddItemView.swift
//  nudge
//
//  Manually capture text, a URL, a photo, and an optional reminder.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddItemViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var isClassifying = false

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                categorySection
                reminderSection
                photoSection
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(context: context)
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .task(id: photoItem) { await loadPhoto() }
        }
    }

    // MARK: Sections

    private var detailsSection: some View {
        Section("Details") {
            TextField("Title", text: $viewModel.title, axis: .vertical)
                .lineLimit(1...3)
                .onSubmit { classify() }

            TextField("URL (optional)", text: $viewModel.urlString)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private var categorySection: some View {
        Section {
            Picker("Category", selection: $viewModel.type) {
                ForEach(ItemType.allCases) { type in
                    Label(type.label, systemImage: type.symbol).tag(type)
                }
            }

            Picker("Priority", selection: $viewModel.priority) {
                ForEach(Priority.allCases) { priority in
                    Text(priority.label).tag(priority)
                }
            }

            Button {
                classify()
            } label: {
                HStack {
                    Label("Suggest a category", systemImage: "wand.and.stars")
                    Spacer()
                    if isClassifying { ProgressView() }
                }
            }
            .disabled(!viewModel.isValid || isClassifying)
        } header: {
            Text("Category")
        } footer: {
            if viewModel.didAutoSuggest {
                Text("Suggested from your text. Change it anytime.")
            }
        }
    }

    private var reminderSection: some View {
        Section("Reminder") {
            Toggle("Remind me", isOn: $viewModel.reminderEnabled.animation())
            if viewModel.reminderEnabled {
                DatePicker(
                    "Date",
                    selection: $viewModel.reminderDate,
                    in: Date.now...,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
    }

    private var photoSection: some View {
        Section("Photo") {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(
                    viewModel.imageData == nil ? "Add a photo" : "Change photo",
                    systemImage: "photo"
                )
            }

            if let data = viewModel.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(.rect(cornerRadius: 12))
                    .accessibilityLabel("Selected photo")

                Button("Remove photo", role: .destructive) {
                    viewModel.imageData = nil
                    photoItem = nil
                }
            }
        }
    }

    // MARK: Actions

    private func classify() {
        Task {
            isClassifying = true
            await viewModel.suggestCategory(using: env.classifier)
            isClassifying = false
        }
    }

    private func loadPhoto() async {
        guard let photoItem else { return }
        if let data = try? await photoItem.loadTransferable(type: Data.self) {
            viewModel.imageData = data
        }
    }
}

#Preview {
    AddItemView()
        .modelContainer(SampleData.previewContainer)
}
