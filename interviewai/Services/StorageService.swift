//
//  StorageService.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

final class StorageService {
    private let fileManager = FileManager.default

    private var appSupportURL: URL {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("InterviewAI")
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private var promptsFileURL: URL {
        appSupportURL.appendingPathComponent("prompts.json")
    }

    private var settingsFileURL: URL {
        appSupportURL.appendingPathComponent("settings.json")
    }

    // MARK: - Prompts

    func loadPrompts() -> [PromptItem] {
        guard let data = try? Data(contentsOf: promptsFileURL),
              let prompts = try? JSONDecoder().decode([PromptItem].self, from: data) else {
            return []
        }
        return prompts.sorted { $0.sortOrder < $1.sortOrder }
    }

    func savePrompts(_ prompts: [PromptItem]) {
        guard let data = try? JSONEncoder().encode(prompts) else { return }
        try? data.write(to: promptsFileURL, options: .atomic)
    }

    // MARK: - Settings

    func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsFileURL),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: settingsFileURL, options: .atomic)
    }
}
