//
//  SystemAudioService.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation
import ScreenCaptureKit
import AVFoundation
import Speech
import Observation

@Observable
final class SystemAudioService {
    var isListening = false
    var currentTranscript = ""
    var error: String?
    var audioLevel: Float = 0

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var stream: SCStream?
    private var streamOutput: AudioStreamOutput?

    @ObservationIgnored
    var onTranscriptUpdate: (@MainActor (SpeechTranscript) -> Void)?

    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.0
    private var isStopping = false
    private var currentTaskID: UUID?

    init() {}

    deinit {
        silenceTimer?.invalidate()
    }

    func updateLanguage(_ identifier: String) {
        let wasListening = isListening
        if wasListening { stopListening() }
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        if wasListening { Task { await startListening() } }
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

        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            return true
        } catch {
            self.error = "Screen recording permission denied, please grant access in System Settings"
            return false
        }
    }

    func startListening() async {
        guard !isListening else { return }
        isStopping = false

        startRecognitionTask()

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)

            guard let display = content.displays.first else {
                self.error = "No display detected"
                return
            }
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])

            let config = SCStreamConfiguration()
            config.capturesAudio = true
            config.excludesCurrentProcessAudio = true
            config.channelCount = 1
            config.sampleRate = 48000
            config.width = 2
            config.height = 2
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

            let output = AudioStreamOutput { [weak self] buffer in
                self?.recognitionRequest?.appendAudioSampleBuffer(buffer)
                let level = Self.calculateLevel(from: buffer)
                Task { @MainActor [weak self] in
                    self?.audioLevel = level
                }
            }
            streamOutput = output

            let newStream = SCStream(filter: filter, configuration: config, delegate: nil)
            try newStream.addStreamOutput(output, type: .audio, sampleHandlerQueue: .global(qos: .default))
            try await newStream.startCapture()
            stream = newStream

            isListening = true
            error = nil
        } catch {
            self.error = "System audio capture failed: \(error.localizedDescription)"
        }
    }

    func stopListening() {
        isStopping = true
        silenceTimer?.invalidate()
        silenceTimer = nil
        isListening = false
        audioLevel = 0

        let currentStream = stream
        stream = nil
        streamOutput = nil

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        Task.detached {
            try? await currentStream?.stopCapture()
        }
    }

    private func restartRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        currentTranscript = ""

        startRecognitionTask()
    }

    private func startRecognitionTask() {
        let taskID = UUID()
        currentTaskID = taskID

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, taskError in
            Task { @MainActor [weak self] in
                guard let self, self.currentTaskID == taskID else { return }

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
                        self.restartRecognition()
                    }
                }

                if let taskError, !self.isStopping {
                    let nsError = taskError as NSError
                    let recoverableCodes = [209, 216, 1110, 1101, 301]
                    if recoverableCodes.contains(nsError.code) || self.isListening {
                        self.restartRecognition()
                    } else {
                        self.error = taskError.localizedDescription
                        self.stopListening()
                    }
                }
            }
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
                    self.restartRecognition()
                }
            }
        }
    }

    nonisolated static func calculateLevel(from buffer: CMSampleBuffer) -> Float {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(buffer) else { return 0 }
        let length = CMBlockBufferGetDataLength(dataBuffer)
        guard length > 0 else { return 0 }

        var data = Data(count: length)
        data.withUnsafeMutableBytes { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            CMBlockBufferCopyDataBytes(dataBuffer, atOffset: 0, dataLength: length, destination: baseAddress)
        }

        let samples = data.withUnsafeBytes {
            Array(UnsafeBufferPointer<Float>(start: $0.baseAddress?.assumingMemoryBound(to: Float.self),
                                              count: length / MemoryLayout<Float>.size))
        }
        guard !samples.isEmpty else { return 0 }

        let rms = sqrt(samples.reduce(0) { $0 + $1 * $1 } / Float(samples.count))
        return min(rms * 5, 1.0)
    }
}

// MARK: - SCStream Audio Output Handler

final class AudioStreamOutput: NSObject, SCStreamOutput, @unchecked Sendable {
    private let onAudioBuffer: @Sendable (CMSampleBuffer) -> Void

    init(onAudioBuffer: @escaping @Sendable (CMSampleBuffer) -> Void) {
        self.onAudioBuffer = onAudioBuffer
    }

    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        onAudioBuffer(sampleBuffer)
    }
}
