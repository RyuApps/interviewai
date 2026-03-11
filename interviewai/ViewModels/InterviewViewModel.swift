//
//  InterviewViewModel.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

@Observable
final class InterviewViewModel {
    let sessionManager = InterviewSessionManager()

    static let maxDuration: TimeInterval = 90 * 60

    var isInterviewMode = false
    private let windowService = WindowService()
    private var interviewStartTime: Date?
    private var timeoutTask: Task<Void, Never>?

    var currentMatch: MatchResult? {
        sessionManager.currentMatch
    }

    var recognizedText: String {
        sessionManager.recognizedText
    }

    var isListening: Bool {
        sessionManager.isListening
    }

    var isProcessing: Bool {
        sessionManager.isProcessing
    }

    var matchHistory: [MatchResult] {
        sessionManager.matchHistory
    }

    var audioLevel: Float {
        sessionManager.audioLevel
    }

    var isLocked: Bool {
        sessionManager.isLocked
    }

    var speechError: String? {
        sessionManager.speechError
    }

    func toggleLock() {
        sessionManager.isLocked.toggle()
    }

    func startInterview(prompts: [PromptItem], settings: AppSettings) async {
        sessionManager.configure(prompts: prompts, settings: settings)
        await sessionManager.startSession()
        isInterviewMode = true
        interviewStartTime = Date()

        timeoutTask?.cancel()
        timeoutTask = Task {
            try? await Task.sleep(for: .seconds(Self.maxDuration))
            guard !Task.isCancelled else { return }
            stopInterview()
            debugLog("[Interview] Session timeout, auto-stopped (90 min)")
        }
    }

    func stopInterview() {
        timeoutTask?.cancel()
        timeoutTask = nil
        interviewStartTime = nil
        sessionManager.stopSession()
        isInterviewMode = false
    }

    func setFloating(_ enabled: Bool) {
        windowService.configureMainWindow(floating: enabled)
    }

    func updateOpacity(_ opacity: Double) {
        windowService.updateOpacity(opacity)
    }
}
