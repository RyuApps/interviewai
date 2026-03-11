//
//  MatchResult.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

struct MatchResult: Identifiable {
    let id: UUID = UUID()
    let prompt: PromptItem
    let confidence: Double
    let matchedQuestion: String
    let timestamp: Date

    init(prompt: PromptItem, confidence: Double, matchedQuestion: String) {
        self.prompt = prompt
        self.confidence = confidence
        self.matchedQuestion = matchedQuestion
        self.timestamp = Date()
    }
}
