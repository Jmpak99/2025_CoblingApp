//
//  QuestViewModel.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation
import SwiftUI

enum Direction {
    case up, down, left, right
    
    func turnedLeft() -> Direction {
            switch self {
            case .up: return .left
            case .left: return .down
            case .down: return .right
            case .right: return .up
            }
        }

        func turnedRight() -> Direction {
            switch self {
            case .up: return .right
            case .right: return .down
            case .down: return .left
            case .left: return .up
            }
        }
    
}

class QuestViewModel: ObservableObject {
    @Published var characterPosition: (row: Int, col: Int) = (4, 0)
    @Published var characterDirection: Direction = .right

    @Published var mapData: [[Int]] = [
        [1, 1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1]
    ]

    @Published var startBlock = Block(type: .start)

    private var isExecuting = false

    func startExecution() {
        guard !isExecuting else {
            print("⚠️ 이미 실행 중입니다.")
            return
        }

        print("🚀 블록 실행 시작")
        isExecuting = true
        executeBlocks(startBlock.children)
    }

    func executeBlocks(_ blocks: [Block], index: Int = 0) {
        guard index < blocks.count else {
            print("✅ 모든 블록 실행 완료")
            isExecuting = false
            return
        }

        let current = blocks[index]
        print("▶️ 현재 실행 중인 블록: \(current.type)")

        switch current.type {
        case .moveForward:
            print("➡️ 앞으로 가기 실행")
            moveForward {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.executeBlocks(blocks, index: index + 1)
                }
            }

        case .turnLeft:
            print("↩️ 왼쪽으로 회전")
            characterDirection = characterDirection.turnedLeft()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }

        case .turnRight:
            print("↪️ 오른쪽으로 회전")
            characterDirection = characterDirection.turnedRight()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }

        default:
            print("⏩ 다른 블록 (미구현), 넘어감")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }
        }
    }


    func moveForward(completion: @escaping () -> Void) {
        var newRow = characterPosition.row
        var newCol = characterPosition.col

        switch characterDirection {
        case .up: newRow -= 1
        case .down: newRow += 1
        case .left: newCol -= 1
        case .right: newCol += 1
        }

        if newRow >= 0, newRow < mapData.count,
           newCol >= 0, newCol < mapData[0].count,
           mapData[newRow][newCol] != 0 {
            characterPosition = (newRow, newCol)
            print("✅ 캐릭터 이동 → 위치: (\(newRow), \(newCol))")
        } else {
            print("❌ 이동 실패: 벽 또는 범위 밖입니다.")
        }

        completion()
    }
}
