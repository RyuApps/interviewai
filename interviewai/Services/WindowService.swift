//
//  WindowService.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import AppKit
import SwiftUI

final class WindowService {

    private var mainWindow: NSWindow? {
        NSApplication.shared.mainWindow ?? NSApplication.shared.windows.first
    }

    func configureMainWindow(floating: Bool) {
        guard let window = mainWindow else { return }

        if floating {
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        } else {
            window.level = .normal
            window.isMovableByWindowBackground = false
            window.collectionBehavior = []
        }
    }

    func updateOpacity(_ opacity: Double) {
        guard let window = mainWindow else { return }
        window.alphaValue = 1.0 - opacity
    }
}
