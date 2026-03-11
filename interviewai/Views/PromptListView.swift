//
//  PromptListView.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import SwiftUI

struct PromptListView: View {
    @Bindable var viewModel: PromptListViewModel
    @State private var showImportPopover = false

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                TextField("Search prompts", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.callout)
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(nsColor: .quaternaryLabelColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(8)

            Divider()

            // Prompt list
            List(selection: $viewModel.selectedPromptID) {
                ForEach(viewModel.filteredPrompts) { prompt in
                    PromptRowView(prompt: prompt)
                        .tag(prompt.id)
                }
                .onMove { source, destination in
                    viewModel.movePrompts(from: source, to: destination)
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Bottom toolbar
            HStack {
                Button {
                    viewModel.addPrompt()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add prompt")

                Button {
                    viewModel.deleteSelected()
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(viewModel.selectedPromptID == nil)
                .help("Delete selected")

                Button {
                    showImportPopover.toggle()
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .help("Import JSON")
                .popover(isPresented: $showImportPopover) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JSON Import")
                            .font(.headline)
                        Text("Prepare a JSON file with the following fields:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("""
                        [\n  {\n    "title": "Question title",\n    "content": "Answer content"\n  }\n]
                        """)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        Button("Choose file...") {
                            showImportPopover = false
                            viewModel.importJSON()
                        }
                        .frame(maxWidth: .infinity)

                        Text("Title max 100 chars, data limit 100 items")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                }

                Spacer()

                Text("\(viewModel.prompts.count) prompts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .focusable(false)
            .padding(8)
            .background(.bar)
        }
        .alert("Import failed", isPresented: .init(
            get: { viewModel.importError != nil },
            set: { if !$0 { viewModel.importError = nil } }
        )) {
            Button("OK") { viewModel.importError = nil }
        } message: {
            switch viewModel.importError {
            case .overCount(let count):
                Text("The file contains \(count) items, but the maximum is 100. Please reduce and try again.")
            case .titleTooLong(let count, let titles):
                Text("The following \(count) titles exceed the 100-character limit. Please edit and try again:\n\n\(titles)")
            case nil:
                EmptyView()
            }
        }
        .alert("Confirm Import", isPresented: .init(
            get: { viewModel.importConfirmation != nil },
            set: { if !$0 { viewModel.cancelImport() } }
        )) {
            Button("Import") {
                if case .pending(_, _, let items) = viewModel.importConfirmation {
                    viewModel.confirmImport(items)
                }
            }
            Button("Cancel", role: .cancel) { viewModel.cancelImport() }
        } message: {
            if case .pending(let existing, let newCount, _) = viewModel.importConfirmation {
                Text("Importing will replace the existing \(existing) prompts with \(newCount) new items. Continue?")
            }
        }
    }
}

struct PromptRowView: View {
    let prompt: PromptItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(prompt.title.isEmpty ? "Untitled" : prompt.title)
                .font(.headline)
                .lineLimit(1)
            Text(prompt.content.isEmpty ? "No content" : prompt.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
