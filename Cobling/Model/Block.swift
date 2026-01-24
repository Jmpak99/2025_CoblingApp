//
//  Block.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//
import Foundation
import SwiftUI

enum BlockType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case start
    case moveForward
    case turnLeft
    case turnRight
    case attack
    case repeatCount
    case repeatForever
    case `if`
    case ifElse
    case breakLoop
    case continueLoop

    var imageName: String {
        switch self {
        case .start: return "block_start"
        case .moveForward: return "block_move"
        case .turnLeft: return "block_turn_left"
        case .turnRight: return "block_turn_right"
        case .attack: return "block_attack"
        case .repeatCount: return "block_repeat_count"
        case .repeatForever: return "block_repeat_forever"
        case .if: return "block_if"
        case .ifElse: return "block_if-else"
        case .breakLoop: return "block_break"
        case .continueLoop: return "block_continue"
        }
    }

    var isContainer: Bool {
        switch self {
        case .repeatCount, .repeatForever, .if, .ifElse:
            return true
        default:
            return false
        }
    }
}

class Block: Identifiable, ObservableObject, Equatable {
    static func == (lhs: Block, rhs: Block) -> Bool {
        lhs.id == rhs.id
    }

    let id = UUID()
    let type: BlockType
    @Published var children: [Block] = []
    weak var parent: Block?
    @Published var value: String?

    init(type: BlockType, value: String? = nil, children: [Block] = []) {
        self.type = type
        self.value = value
        self.children = children
        for child in children {
            child.parent = self
        }
    }
}
