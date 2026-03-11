//
//  SettingsView.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Bindable var promptVM: PromptListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = "prompts"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedTab) {
                    Text("Prompts").tag("prompts")
                    Text("Appearance").tag("appearance")
                    Text("General").tag("general")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            switch selectedTab {
            case "prompts":
                promptManagementTab
            case "appearance":
                appearanceTab
            case "general":
                generalTab
            default:
                promptManagementTab
            }
        }
    }

    // MARK: - Prompt Management

    private var promptManagementTab: some View {
        NavigationSplitView {
            PromptListView(viewModel: promptVM)
                .frame(minWidth: 200)
        } detail: {
            PromptEditorView(viewModel: promptVM)
                .frame(minWidth: 300)
        }
    }

    // MARK: - Appearance

    private var appearanceTab: some View {
        Form {
            Section("Window") {
                Toggle("Always on top during interview", isOn: $viewModel.settings.alwaysOnTop)
                HStack {
                    Text("Background opacity")
                    Slider(value: $viewModel.settings.overlayOpacity, in: 0.1...1.0, step: 0.05)
                    Text("\(Int(viewModel.settings.overlayOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }

            Section("Title Style") {
                Toggle("Show question title", isOn: $viewModel.settings.showTitle)

                HStack {
                    Text("Title font size")
                    Slider(value: $viewModel.settings.titleFontSize, in: 12...36, step: 1)
                    Text("\(Int(viewModel.settings.titleFontSize))pt")
                        .monospacedDigit()
                        .frame(width: 40)
                }

                colorPicker(label: "Title color", color: $viewModel.settings.titleColor)

                Text("Title preview text")
                    .font(.system(size: viewModel.settings.titleFontSize, weight: .bold))
                    .foregroundStyle(viewModel.settings.titleColor.swiftUIColor)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Section("Content Style") {
                HStack {
                    Text("Content font size")
                    Slider(value: $viewModel.settings.contentFontSize, in: 10...30, step: 1)
                    Text("\(Int(viewModel.settings.contentFontSize))pt")
                        .monospacedDigit()
                        .frame(width: 40)
                }

                colorPicker(label: "Content color", color: $viewModel.settings.contentColor)

                Text("Content preview text, this is a sample answer.")
                    .font(.system(size: viewModel.settings.contentFontSize))
                    .foregroundStyle(viewModel.settings.contentColor.swiftUIColor)
                    .lineSpacing(4)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .onChange(of: viewModel.settings) { _, _ in viewModel.save() }
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Speech Recognition") {
                Picker("Audio source", selection: $viewModel.settings.audioSource) {
                    ForEach(AudioSource.allCases, id: \.self) { source in
                        Text(source.displayName).tag(source)
                    }
                }

                if viewModel.settings.audioSource == .systemAudio {
                    Text("Capture audio output from Zoom / Teams / Meet, requires screen recording permission")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Listen via microphone, may pick up your own voice and ambient noise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Recognition language", selection: $viewModel.settings.speechLanguage) {
                    ForEach(AppSettings.supportedLanguages, id: \.id) { lang in
                        Text(lang.name).tag(lang.id)
                    }
                }
            }

            Section {
                Button("Reset to defaults") {
                    viewModel.resetToDefaults()
                }
            }

            Section("Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .onChange(of: viewModel.settings) { _, _ in viewModel.save() }
    }

    // MARK: - Color Picker

    private func colorPicker(label: String, color: Binding<CodableColor>) -> some View {
        HStack {
            Text(label)
            Spacer()
            ForEach(presetColors, id: \.name) { preset in
                Button {
                    color.wrappedValue = preset.color
                } label: {
                    Circle()
                        .fill(preset.color.swiftUIColor)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: color.wrappedValue == preset.color ? 2 : 0)
                        )
                }
                .buttonStyle(.plain)
                .help(preset.name)
            }
        }
    }

    private var presetColors: [(name: String, color: CodableColor)] {
        [
            ("White", .white),
            ("Yellow", .yellow),
            ("Cyan", .cyan),
            ("Green", .green),
            ("Orange", CodableColor(red: 1, green: 0.6, blue: 0.2)),
            ("Pink", CodableColor(red: 1, green: 0.5, blue: 0.7)),
            ("Red", CodableColor(red: 1, green: 0.3, blue: 0.3)),
            ("Purple", CodableColor(red: 0.7, green: 0.4, blue: 1)),
            ("Blue", CodableColor(red: 0.4, green: 0.5, blue: 1)),
            ("Gray", CodableColor(red: 0.7, green: 0.7, blue: 0.7)),
        ]
    }
}
