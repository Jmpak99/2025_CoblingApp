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
    @Published var showFailureDialog: Bool = false
    @Published var showSuccessDialog: Bool = false
    @Published var mapData: [[Int]] = [
        [1, 1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1]
    ]
    @Published var startBlock = Block(type: .start)
    
    private var isExecuting = false
    private let initialPosition = (row: 4, col: 0)
    private let goalTile = 2

    func startExecution() {
        guard !isExecuting else { return }
        isExecuting = true
        executeBlocks(startBlock.children)
    }

    func executeBlocks(_ blocks: [Block], index: Int = 0) {
        guard index < blocks.count else {
            print("✅ 모든 블록 실행 완료")
            // ✅ 모든 블록이 끝났는데 도착 타일(2)이 아니면 실패 처리
            if mapData[characterPosition.row][characterPosition.col] != goalTile {
                print("❌ 실패: 깃발에 도달하지 못함")
                resetToStart()
            } else {
                print("🎉 성공: 깃발 도착!")
                showSuccessDialog = true // 성공 다이얼로그 띄우기
                isExecuting = false
            }
            return
        }

        let current = blocks[index]
        print("▶️ 현재 실행 중인 블록: \(current.type)")

        switch current.type {
        case .moveForward:
            moveForward {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.executeBlocks(blocks, index: index + 1)
                }
            }

        case .turnLeft:
            characterDirection = characterDirection.turnedLeft()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }

        case .turnRight:
            characterDirection = characterDirection.turnedRight()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }

        default:
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
            completion()
        } else {
            print("❌ 이동 실패: 벽 또는 범위 밖입니다.")
            resetToStart()
        }
    }

    func resetToStart() {
        isExecuting = false
        characterPosition = initialPosition
        characterDirection = .right
        showFailureDialog = true
        print("🔁 캐릭터를 시작 위치로 되돌림")
    }
    
    func resetExecution() {
        isExecuting = false
        characterPosition = initialPosition
        characterDirection = .right
        showFailureDialog = false
        showSuccessDialog = false // ✅ 이 줄 추가!
        print("🔄 다시하기: 캐릭터 초기화 및 다이얼로그 종료")
    }
}

