//
//  AppSettings.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation
import SwiftUI

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double

    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let yellow = CodableColor(red: 1, green: 0.85, blue: 0.2)
    static let cyan = CodableColor(red: 0.4, green: 0.85, blue: 1)
    static let green = CodableColor(red: 0.4, green: 0.9, blue: 0.4)

    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue)
    }
}

enum AudioSource: String, Codable, CaseIterable {
    case systemAudio = "systemAudio"
    case microphone = "microphone"

    var displayName: String {
        switch self {
        case .systemAudio: "System Audio (Recommended)"
        case .microphone: "Microphone"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var overlayOpacity: Double
    var showTitle: Bool
    var alwaysOnTop: Bool
    var speechLanguage: String
    var audioSource: AudioSource

    // Title style
    var titleFontSize: Double
    var titleColor: CodableColor

    // Content style
    var contentFontSize: Double
    var contentColor: CodableColor

    static let supportedLanguages: [(id: String, name: String)] = [
        ("ar-SA", "العربية"),
        ("ca-ES", "Català"),
        ("cs-CZ", "Čeština"),
        ("da-DK", "Dansk"),
        ("de-DE", "Deutsch"),
        ("el-GR", "Ελληνικά"),
        ("en-AU", "English (AU)"),
        ("en-GB", "English (UK)"),
        ("en-IN", "English (IN)"),
        ("en-US", "English (US)"),
        ("es-ES", "Español (España)"),
        ("es-MX", "Español (México)"),
        ("fi-FI", "Suomi"),
        ("fr-FR", "Français"),
        ("he-IL", "עברית"),
        ("hi-IN", "हिन्दी"),
        ("hr-HR", "Hrvatski"),
        ("hu-HU", "Magyar"),
        ("id-ID", "Bahasa Indonesia"),
        ("it-IT", "Italiano"),
        ("ja-JP", "日本語"),
        ("ko-KR", "한국어"),
        ("ms-MY", "Bahasa Melayu"),
        ("nb-NO", "Norsk"),
        ("nl-NL", "Nederlands"),
        ("pl-PL", "Polski"),
        ("pt-BR", "Português (Brasil)"),
        ("pt-PT", "Português (Portugal)"),
        ("ro-RO", "Română"),
        ("ru-RU", "Русский"),
        ("sk-SK", "Slovenčina"),
        ("sv-SE", "Svenska"),
        ("th-TH", "ไทย"),
        ("tr-TR", "Türkçe"),
        ("uk-UA", "Українська"),
        ("vi-VN", "Tiếng Việt"),
        ("zh-Hans", "中文（简体）"),
        ("zh-Hant-TW", "中文（繁體）"),
    ]

    init(
        overlayOpacity: Double = 0.15,
        showTitle: Bool = true,
        alwaysOnTop: Bool = true,
        speechLanguage: String = "en-US",
        audioSource: AudioSource = .systemAudio,
        titleFontSize: Double = 18,
        titleColor: CodableColor = .cyan,
        contentFontSize: Double = 15,
        contentColor: CodableColor = .white
    ) {
        self.overlayOpacity = overlayOpacity
        self.showTitle = showTitle
        self.alwaysOnTop = alwaysOnTop
        self.speechLanguage = speechLanguage
        self.audioSource = audioSource
        self.titleFontSize = titleFontSize
        self.titleColor = titleColor
        self.contentFontSize = contentFontSize
        self.contentColor = contentColor
    }
}
