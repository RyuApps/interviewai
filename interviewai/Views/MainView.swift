//
//  MainView.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import SwiftUI

struct MainView: View {
    @State private var promptVM = PromptListViewModel()
    @State private var interviewVM = InterviewViewModel()
    @State private var settingsVM = SettingsViewModel()
    @State private var showSettings = false
    @State private var showMatchBorder = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderBarView(
                interviewVM: interviewVM,
                promptVM: promptVM,
                settingsVM: settingsVM,
                showSettings: $showSettings
            )

            Divider()

            if interviewVM.isInterviewMode {
                InterviewContentView(
                    interviewVM: interviewVM,
                    settingsVM: settingsVM
                )
            } else {
                HomeContentView(
                    promptCount: promptVM.prompts.count,
                    speechError: interviewVM.speechError
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(matchBorderOverlay)
        .onChange(of: interviewVM.currentMatch?.prompt.id) { _, newValue in
            guard newValue != nil else { return }
            showMatchBorder = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showMatchBorder = false
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: settingsVM, promptVM: promptVM)
                .frame(minWidth: 600, minHeight: 500)
        }
        .onAppear {
            promptVM.load()
            interviewVM.updateOpacity(settingsVM.settings.overlayOpacity)
        }
        .onChange(of: interviewVM.isInterviewMode) { _, isActive in
            interviewVM.setFloating(isActive && settingsVM.settings.alwaysOnTop)
        }
        .onChange(of: settingsVM.settings.alwaysOnTop) { _, newValue in
            if interviewVM.isInterviewMode {
                interviewVM.setFloating(newValue)
            }
        }
        .onChange(of: settingsVM.settings.overlayOpacity) { _, newValue in
            interviewVM.updateOpacity(newValue)
        }
    }

    private var matchBorderOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.6), lineWidth: 6)
                .blur(radius: 8)
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 12)
                .blur(radius: 16)
        }
        .opacity(showMatchBorder ? 1 : 0)
        .animation(.easeInOut(duration: 0.4), value: showMatchBorder)
    }
}

// MARK: - Header Bar

struct HeaderBarView: View {
    let interviewVM: InterviewViewModel
    let promptVM: PromptListViewModel
    let settingsVM: SettingsViewModel
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 10) {
            if interviewVM.isInterviewMode {
                Circle()
                    .fill(interviewVM.isListening ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(interviewVM.isListening ? "Listening..." : "Stopped")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Image("BotIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 28)
                Text("Interview AI")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            if interviewVM.isInterviewMode {
                Button {
                    interviewVM.stopInterview()
                } label: {
                    Label("End Interview", systemImage: "stop.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.regular)
            } else {
                Button {
                    Task {
                        await interviewVM.startInterview(
                            prompts: promptVM.prompts,
                            settings: settingsVM.settings
                        )
                    }
                } label: {
                    Label("Start Interview", systemImage: "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(minHeight: 56)
        .background(.bar)
    }
}

// MARK: - Home Content

struct HomeContentView: View {
    let promptCount: Int
    let speechError: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("Relax, be confident — you've got this!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(promptCount) questions prepared")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }

            if let error = speechError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Interview Content

struct InterviewContentView: View {
    let interviewVM: InterviewViewModel
    let settingsVM: SettingsViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    interviewVM.toggleLock()
                } label: {
                    Label(
                        interviewVM.isLocked ? "Locked" : "Lock current answer",
                        systemImage: interviewVM.isLocked ? "lock.fill" : "lock.open"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .tint(interviewVM.isLocked ? .orange : nil)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                MatchResultView(
                    match: interviewVM.currentMatch,
                    settings: settingsVM.settings,
                    isListening: interviewVM.isListening
                )

                Divider()

                SpeechWaveformView(
                    audioLevel: interviewVM.audioLevel,
                    recognizedText: interviewVM.recognizedText
                )
            }

            if interviewVM.isProcessing {
                Text("Analyzing...")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.leading, 16)
                    .padding(.top, 8)
            } else if interviewVM.currentMatch != nil {
                Text("Match result")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Match Result

struct MatchResultView: View {
    let match: MatchResult?
    let settings: AppSettings
    let isListening: Bool

    var body: some View {
        Group {
            if let match {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if settings.showTitle {
                            Text(match.prompt.title)
                                .font(.system(size: settings.titleFontSize, weight: .bold))
                                .foregroundStyle(settings.titleColor.swiftUIColor)
                        }

                        Text(match.prompt.content)
                            .font(.system(size: settings.contentFontSize))
                            .foregroundStyle(settings.contentColor.swiftUIColor)
                            .textSelection(.enabled)
                            .lineSpacing(4)
                    }
                    .padding(16)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                        .symbolEffect(.variableColor.iterative, isActive: isListening)
                    Text("Waiting for interviewer's question...")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Speech Waveform

struct SpeechWaveformView: View {
    let audioLevel: Float
    let recognizedText: String

    var body: some View {
        ZStack {
            if audioLevel > 0.01 {
                HStack(spacing: 2) {
                    ForEach(0..<25, id: \.self) { i in
                        SpeechBar(level: CGFloat(audioLevel), index: i)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 12)
                .clipped()
                .opacity(0.3)
            }

            HStack {
                Image(systemName: "mic.fill")
                    .font(.caption2)
                    .foregroundStyle(audioLevel > 0.01 ? .green : .secondary)
                Text(recognizedText.isEmpty ? " " : recognizedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(.bar)
    }
}

// MARK: - Speech Bar

struct SpeechBar: View {
    let level: CGFloat
    let index: Int

    var body: some View {
        let baseHeight = max(2, level * 10)
        let variation = sin(Double(index) * 0.8) * 0.5 + 0.5
        let height = min(max(2, baseHeight * CGFloat(variation)), 12)

        RoundedRectangle(cornerRadius: 1)
            .fill(Color.green)
            .frame(width: 2, height: height)
            .animation(.easeOut(duration: 0.1), value: level)
    }
}
