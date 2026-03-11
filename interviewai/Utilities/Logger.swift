//
//  Logger.swift
//  interviewai
//
//  Created by Ryu on 2026/03/11.
//

import Foundation

func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let message = items.map { "\($0)" }.joined(separator: separator)
    print(message, terminator: terminator)
    #endif
}
