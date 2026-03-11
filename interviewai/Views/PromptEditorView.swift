//
//  PromptEditorView.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import SwiftUI

struct PromptEditorView: View {
    @Bindable var viewModel: PromptListViewModel

    var body: some View {
        Group {
            if let index = selectedIndex {
                editorContent(at: index)
            } else {
                emptyState
            }
        }
        .onDisappear { viewModel.save() }
    }

    private var selectedIndex: Int? {
        guard let id = viewModel.selectedPromptID else { return nil }
        return viewModel.prompts.firstIndex(where: { $0.id == id })
    }

    private func editorContent(at index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Enter question title...", text: $viewModel.prompts[index].title)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .onChange(of: viewModel.prompts[index].title) {
                        viewModel.truncateTitle(at: index)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Answer Content")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $viewModel.prompts[index].content)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Select a prompt to edit")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Or create a new one with the + button")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
