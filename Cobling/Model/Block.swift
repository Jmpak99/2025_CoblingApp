//
//  Block.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//

import Foundation
import SwiftUI

// MARK: - 블록 타입 정의

enum BlockType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case start          // 시작하기
    case moveForward    // 앞으로 가기
    case turnLeft       // 왼쪽으로 돌기
    case turnRight      // 오른쪽으로 돌기
    case attack         // 공격하기
    case repeatCount    // -번 반복하기
    case repeatForever  // 계속 반복하기
    case `if`           // 만약 ~라면
    case ifElse         // 만약 ~라면 아니면
    case breakLoop      // 반복 중단하기
    case continueLoop   // 계속하기

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

// MARK: - 블록 모델

class Block: Identifiable, ObservableObject {
    let id = UUID()
    let type: BlockType

    // container block일 경우 자식 블록 (Tree 구조)
    @Published var children: [Block] = []

    // 부모 블록 참조 (필요한 경우)
    weak var parent: Block?

    // 반복 횟수나 조건문 등을 위한 텍스트 값 (예: 3회 반복 등)
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
