//
//  SpeechService.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation
import Speech
import AVFoundation
import Observation

@Observable
final class SpeechService {
    var isListening = false
    var currentTranscript = ""
    var error: String?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private nonisolated(unsafe) let audioEngine = AVAudioEngine()
    private let audioQueue = DispatchQueue(label: "com.interviewai.audio", qos: .default)

    @ObservationIgnored
    var onTranscriptUpdate: (@MainActor (SpeechTranscript) -> Void)?

    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.0
    private var isStopping = false

    init() {}

    deinit {
        silenceTimer?.invalidate()
    }

    func updateLanguage(_ identifier: String) {
        let wasListening = isListening
        if wasListening { stopListening() }
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        if wasListening { startListening() }
    }

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            error = "Speech recognition permission denied"
            return false
        }
        return true
    }

    func startListening() {
        guard !isListening else { return }
        isStopping = false

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, taskError in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    let text = result.bestTranscription.formattedString
                    self.currentTranscript = text
                    self.resetSilenceTimer()

                    let transcript = SpeechTranscript(
                        text: text,
                        timestamp: Date(),
                        isFinal: result.isFinal
                    )
                    self.onTranscriptUpdate?(transcript)

                    if result.isFinal {
                        self.restartListening()
                    }
                }

                if let taskError, !self.isStopping {
                    self.error = taskError.localizedDescription
                    self.stopListening()
                }
            }
        }

        let engine = audioEngine
        let request = recognitionRequest
        audioQueue.async { [weak self] in
            let node = engine.inputNode
            let recordingFormat = node.outputFormat(forBus: 0)

            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            engine.prepare()
            do {
                try engine.start()
                Task { @MainActor [weak self] in
                    self?.isListening = true
                    self?.error = nil
                }
            } catch {
                Task { @MainActor [weak self] in
                    self?.error = "Audio engine failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func stopListening() {
        isStopping = true
        silenceTimer?.invalidate()
        silenceTimer = nil
        isListening = false

        let engine = audioEngine
        let request = recognitionRequest
        let task = recognitionTask
        recognitionRequest = nil
        recognitionTask = nil

        audioQueue.async {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            request?.endAudio()
            task?.cancel()
        }
    }

    private func restartListening() {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.startListening()
        }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if !self.currentTranscript.isEmpty {
                    let transcript = SpeechTranscript(
                        text: self.currentTranscript,
                        timestamp: Date(),
                        isFinal: true
                    )
                    self.onTranscriptUpdate?(transcript)
                    self.restartListening()
                }
            }
        }
    }
}
