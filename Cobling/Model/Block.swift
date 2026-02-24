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

enum IfCondition: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case frontIsClear
    case frontIsBlocked
    case atFlag
    case always

    var label: String {
        switch self {
        case .frontIsClear: return "앞이 비어있으면"
        case .frontIsBlocked: return "앞이 막혀있으면"
        case .atFlag: return "깃발에 도착했으면"
        case .always: return "항상"
        }
    }
}


class Block: Identifiable, ObservableObject, Equatable {
    static func == (lhs: Block, rhs: Block) -> Bool {
        lhs.id == rhs.id
    }

    let id = UUID()
    let type: BlockType
    
    // 공통: 컨테이너 기본 영역(Repeat, if(then)은 여기 사용)
    @Published var children: [Block] = []
    
    // ifElse 전용 else 영역 (if는 비워둬도 됨)
    @Published var elseChildren: [Block] = []
    
    weak var parent: Block?
    
    // repeatCount 등 값
    @Published var value: String?
    
    // if 조건값
    @Published var condition: IfCondition = .frontIsClear

    init(
        type: BlockType,
        value: String? = nil,
        condition: IfCondition = .frontIsClear,
        children: [Block] = [],
        elseChildren: [Block] = []
    ) {
        self.type = type
        self.value = value
        self.condition = condition

        self.children = children
        self.elseChildren = elseChildren

        for child in children { child.parent = self }
        for child in elseChildren { child.parent = self }
    }
}
