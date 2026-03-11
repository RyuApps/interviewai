//
//  SpeechTranscript.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

struct SpeechTranscript: Identifiable {
    let id: UUID = UUID()
    let text: String
    let timestamp: Date
    let isFinal: Bool
}
