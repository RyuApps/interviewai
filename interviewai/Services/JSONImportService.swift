//
//  JSONImportService.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

struct JSONPromptDTO: Codable {
    let title: String
    let content: String
}

final class JSONImportService {

    func importFromFile(startingOrder: Int = 0) -> [PromptItem]? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Import Prompts JSON"

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return parseJSON(from: url, startingOrder: startingOrder)
    }

    func parseJSON(from url: URL, startingOrder: Int = 0) -> [PromptItem]? {
        guard let data = try? Data(contentsOf: url),
              let dtos = try? JSONDecoder().decode([JSONPromptDTO].self, from: data) else {
            return nil
        }

        return dtos.enumerated().map { index, dto in
            PromptItem(
                title: dto.title,
                content: dto.content,
                sortOrder: startingOrder + index
            )
        }
    }
}
