//
//  PromptItem.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

struct PromptItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var sortOrder: Int

    init(id: UUID = UUID(), title: String = "", content: String = "", sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.content = content
        self.sortOrder = sortOrder
    }
}
