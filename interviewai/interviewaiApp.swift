//
//  interviewaiApp.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import SwiftUI

@main
struct interviewaiApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 400, minHeight: 350)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 480, height: 400)
    }
}
