//
//  InterviewSessionManager.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

@Observable
final class InterviewSessionManager {
    let micSpeechService = SpeechService()
    let systemAudioService = SystemAudioService()
    let aiService = AIService()

    var isSessionActive = false
    var currentMatch: MatchResult?
    var recognizedText = ""
    var isProcessing = false
    var matchHistory: [MatchResult] = []
    var isLocked = false

    private var prompts: [PromptItem] = []
    private var settings: AppSettings = AppSettings()
    private var lastProcessedText = ""
    private var lastMatchedPromptID: UUID?
    private var activeSource: AudioSource = .systemAudio
    private let partialMatchThreshold = 4
    private let questionMaxLength = 500

    var isListening: Bool {
        switch activeSource {
        case .systemAudio: systemAudioService.isListening
        case .microphone: micSpeechService.isListening
        }
    }

    var audioLevel: Float {
        switch activeSource {
        case .systemAudio: systemAudioService.audioLevel
        case .microphone: 0
        }
    }

    var speechError: String? {
        switch activeSource {
        case .systemAudio: systemAudioService.error
        case .microphone: micSpeechService.error
        }
    }

    func configure(prompts: [PromptItem], settings: AppSettings) {
        self.prompts = prompts
        self.settings = settings
        self.activeSource = settings.audioSource
        aiService.prepareIndex(prompts: prompts)
    }

    func startSession() async {
        currentMatch = nil
        matchHistory = []
        recognizedText = ""
        lastProcessedText = ""
        isLocked = false

        let onTranscript: @MainActor (SpeechTranscript) -> Void = { [weak self] transcript in
            guard let self else { return }
            self.recognizedText = transcript.text

            let text = transcript.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if transcript.isFinal {
                self.processTranscript(text)
            } else if text.count >= self.partialMatchThreshold {
                self.processPartialMatch(text)
            }
        }

        switch activeSource {
        case .systemAudio:
            let granted = await systemAudioService.requestPermissions()
            guard granted else { return }
            systemAudioService.onTranscriptUpdate = onTranscript
            systemAudioService.updateLanguage(settings.speechLanguage)
            await systemAudioService.startListening()

        case .microphone:
            let granted = await micSpeechService.requestPermissions()
            guard granted else { return }
            micSpeechService.onTranscriptUpdate = onTranscript
            micSpeechService.updateLanguage(settings.speechLanguage)
            micSpeechService.startListening()
        }

        isSessionActive = true
    }

    func stopSession() {
        switch activeSource {
        case .systemAudio:
            systemAudioService.stopListening()
        case .microphone:
            micSpeechService.stopListening()
        }
        isSessionActive = false
        recognizedText = ""
    }

    private func processPartialMatch(_ text: String) {
        guard !text.isEmpty, text != lastProcessedText, !isLocked else { return }
        lastProcessedText = text

        if let result = aiService.findBestMatch(question: text, prompts: prompts) {
            if result.prompt.id != lastMatchedPromptID {
                currentMatch = result
                lastMatchedPromptID = result.prompt.id
            }
        }
    }

    private func processTranscript(_ text: String) {
        guard !text.isEmpty, !isProcessing, !isLocked else { return }

        let question = text.count > questionMaxLength
            ? String(text.suffix(questionMaxLength))
            : text

        isProcessing = true
        lastProcessedText = text

        if let result = aiService.findBestMatch(question: question, prompts: prompts) {
            currentMatch = result
            lastMatchedPromptID = result.prompt.id
            matchHistory.insert(result, at: 0)
            if matchHistory.count > 20 {
                matchHistory = Array(matchHistory.prefix(20))
            }
        }

        isProcessing = false
    }
}
