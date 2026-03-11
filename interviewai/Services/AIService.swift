//
//  AIService.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

final class AIService {

    // MARK: - Pre-computed cache

    private struct PromptIndex {
        let prompt: PromptItem
        let titleNorm: String
        let contentNorm: String
        let titleNgrams: [String: Int]
        let contentNgrams: [String: Int]
        let titleCharSet: Set<Character>
        let contentCharSet: Set<Character>
    }

    private var promptIndex: [PromptIndex] = []
    private var idfCache: [Character: Double] = [:]
    private let minimumConfidence = 0.15

    func prepareIndex(prompts: [PromptItem]) {
        idfCache = buildIDF(prompts: prompts)
        promptIndex = prompts.map { prompt in
            let tNorm = normalize(prompt.title)
            let cNorm = normalize(prompt.content)
            return PromptIndex(
                prompt: prompt,
                titleNorm: tNorm,
                contentNorm: cNorm,
                titleNgrams: ngrams(tNorm, sizes: [2, 3, 4]),
                contentNgrams: ngrams(cNorm, sizes: [2, 3, 4]),
                titleCharSet: Set(tNorm.filter { !$0.isWhitespace }),
                contentCharSet: Set(cNorm.filter { !$0.isWhitespace })
            )
        }
    }

    func findBestMatch(question: String, prompts: [PromptItem]) -> MatchResult? {
        guard !prompts.isEmpty,
              !question.trimmingCharacters(in: .whitespaces).isEmpty,
              !promptIndex.isEmpty else {
            return nil
        }

        let questionNorm = normalize(question)
        guard questionNorm.count >= 2 else { return nil }

        let qNgrams = ngrams(questionNorm, sizes: [2, 3, 4])
        let qCharSet = Set(questionNorm.filter { !$0.isWhitespace })

        var bestScore = 0.0
        var bestEntry: PromptIndex?

        for entry in promptIndex {
            var score = 0.0

            // 1) Substring match: title appears directly in question
            if !entry.titleNorm.isEmpty && questionNorm.contains(entry.titleNorm) {
                score += Double(entry.titleNorm.count) * 20.0
            }

            // 2) N-gram match (with IDF weighting)
            for (gram, qCount) in qNgrams {
                let weight = gramIDF(gram)
                if let tCount = entry.titleNgrams[gram] {
                    score += Double(min(qCount, tCount)) * weight * 10.0
                }
                if let cCount = entry.contentNgrams[gram] {
                    score += Double(min(qCount, cCount)) * weight * 2.0
                }
            }

            // 3) Single character match (IDF weighted)
            for char in qCharSet {
                let w = idfCache[char] ?? 1.0
                if entry.titleCharSet.contains(char) { score += w * 3.0 }
                if entry.contentCharSet.contains(char) { score += w * 0.5 }
            }

            if score > bestScore {
                bestScore = score
                bestEntry = entry
            }
        }

        guard let matched = bestEntry else { return nil }

        let maxPossible = qNgrams.values.reduce(0.0) { sum, count in
            sum + Double(count) * 10.0
        } + Double(questionNorm.count) * 3.0
        let confidence = maxPossible > 0 ? min(bestScore / maxPossible, 1.0) : 0

        guard confidence >= minimumConfidence else { return nil }
        return MatchResult(prompt: matched.prompt, confidence: confidence, matchedQuestion: question)
    }

    // MARK: - Text Processing

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .filter { !$0.isPunctuation && !$0.isSymbol }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func ngrams(_ text: String, sizes: [Int]) -> [String: Int] {
        let chars = Array(text)
        var result: [String: Int] = [:]
        for n in sizes where chars.count >= n {
            for i in 0...(chars.count - n) {
                let gram = String(chars[i..<i+n])
                if gram.allSatisfy({ $0.isWhitespace }) { continue }
                result[gram, default: 0] += 1
            }
        }
        return result
    }

    private func buildIDF(prompts: [PromptItem]) -> [Character: Double] {
        let totalDocs = Double(prompts.count)
        var docFreq: [Character: Int] = [:]

        for prompt in prompts {
            let chars = Set(normalize(prompt.title))
            for char in chars where !char.isWhitespace {
                docFreq[char, default: 0] += 1
            }
        }

        var idf: [Character: Double] = [:]
        for (char, freq) in docFreq {
            idf[char] = log(1.0 + totalDocs / Double(freq))
        }
        return idf
    }

    private func gramIDF(_ gram: String) -> Double {
        let weights = gram.compactMap { idfCache[$0] }
        guard !weights.isEmpty else { return 1.0 }
        return weights.reduce(0.0, +) / Double(weights.count)
    }
}
