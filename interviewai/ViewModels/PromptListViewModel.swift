//
//  PromptListViewModel.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import SwiftUI

enum ImportError: Equatable {
    case overCount(Int)
    case titleTooLong(count: Int, titles: String)
}

enum ImportConfirmation: Equatable {
    case pending(existingCount: Int, newCount: Int, items: [PromptItem])

    static func == (lhs: ImportConfirmation, rhs: ImportConfirmation) -> Bool {
        switch (lhs, rhs) {
        case let (.pending(l1, l2, _), .pending(r1, r2, _)):
            return l1 == r1 && l2 == r2
        }
    }
}

@Observable
final class PromptListViewModel {
    var prompts: [PromptItem] = []
    var selectedPromptID: UUID? {
        didSet { save() }
    }
    var searchText = ""
    var importError: ImportError?
    var importConfirmation: ImportConfirmation?

    private let storageService = StorageService()
    private let jsonImportService = JSONImportService()

    var filteredPrompts: [PromptItem] {
        if searchText.isEmpty {
            return prompts
        }
        return prompts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() {
        prompts = storageService.loadPrompts()
        if prompts.isEmpty {
            loadSamplePrompts()
        }
    }

    func addPrompt() {
        let newPrompt = PromptItem(
            title: "New Prompt",
            content: "",
            sortOrder: prompts.count
        )
        prompts.append(newPrompt)
        selectedPromptID = newPrompt.id
        save()
    }

    func deletePrompt(_ prompt: PromptItem) {
        prompts.removeAll { $0.id == prompt.id }
        if selectedPromptID == prompt.id {
            selectedPromptID = prompts.first?.id
        }
        reindex()
        save()
    }

    func deleteSelected() {
        guard let id = selectedPromptID,
              let prompt = prompts.first(where: { $0.id == id }) else { return }
        deletePrompt(prompt)
    }

    func movePrompts(from source: IndexSet, to destination: Int) {
        prompts.move(fromOffsets: source, toOffset: destination)
        reindex()
        save()
    }

    func truncateTitle(at index: Int) {
        if prompts[index].title.count > 100 {
            prompts[index].title = String(prompts[index].title.prefix(100))
        }
    }

    func importJSON() {
        guard let imported = jsonImportService.importFromFile(startingOrder: 0) else { return }

        if imported.count > 100 {
            importError = .overCount(imported.count)
            return
        }

        let overLengthTitles = imported.filter { $0.title.count > 100 }
        if !overLengthTitles.isEmpty {
            let titleList = overLengthTitles.map { "- \($0.title.prefix(50))..." }.joined(separator: "\n")
            importError = .titleTooLong(count: overLengthTitles.count, titles: titleList)
            return
        }

        importConfirmation = .pending(existingCount: prompts.count, newCount: imported.count, items: imported)
    }

    func confirmImport(_ items: [PromptItem]) {
        prompts = items
        selectedPromptID = prompts.first?.id
        importConfirmation = nil
        save()
    }

    func cancelImport() {
        importConfirmation = nil
    }

    func save() {
        storageService.savePrompts(prompts)
    }

    private func reindex() {
        for i in prompts.indices {
            prompts[i].sortOrder = i
        }
    }

    private func loadSamplePrompts() {
        guard let url = Bundle.main.url(forResource: "SamplePrompts", withExtension: "json") else { return }
        if let items = jsonImportService.parseJSON(from: url) {
            prompts = items
            save()
        }
    }
}
