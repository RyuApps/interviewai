//
//  SettingsViewModel.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

@Observable
final class SettingsViewModel {
    var settings: AppSettings

    private let storageService = StorageService()

    init() {
        self.settings = StorageService().loadSettings()
    }

    func save() {
        storageService.saveSettings(settings)
    }

    func resetToDefaults() {
        settings = AppSettings()
        save()
    }
}
