//
//  QuestViewModel.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation
import SwiftUI

// MARK: - 캐릭터 방향 열거형 정의
enum Direction {
    case up, down, left, right // 4방향 정의
    
    // 왼쪽으로 회전 시 방향 반환
    func turnedLeft() -> Direction {
            switch self {
            case .up: return .left
            case .left: return .down
            case .down: return .right
            case .right: return .up
            }
        }

    // 오른쪽으로 회전 시 방향 반환
    func turnedRight() -> Direction {
            switch self {
            case .up: return .right
            case .right: return .down
            case .down: return .left
            case .left: return .up
            }
        }
    
}

// MARK: - 퀘스트 실행 뷰모델
class QuestViewModel: ObservableObject {
    @Published var characterPosition: (row: Int, col: Int) = (4, 0) // 캐릭터 현재 위치
    @Published var characterDirection: Direction = .right // 캐릭터 현재 방향
    @Published var showFailureDialog: Bool = false // 실패 다이얼로그 표시 여부
    @Published var showSuccessDialog: Bool = false // 성공 다이얼로그 표시 여부
    @Published var mapData: [[Int]] = [ // 게임 맵 정보 (0 : 벽, 1 : 길, 2 : 깃발)
        [0, 0, 0, 0, 0, 0, 2],
        [0, 0, 0, 0, 1, 1, 1],
        [0, 0, 0, 0, 1, 0, 0],
        [0, 0, 1, 1, 1, 0, 0],
        [1, 1, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0],
    ]
    @Published var startBlock = Block(type: .start) // 시작 블록 (루트 블록)
    
    private var isExecuting = false // 실행 중 여부
    private let initialPosition = (row: 4, col: 0) // 시작 위치
    private let goalTile = 2 // 도착 지점(깃발) 타일값
    
    // MARK: - 블록 실행 시작
    func startExecution() {
        guard !isExecuting else { return } // 이미 실행 중이면 중복 실행 방지
        isExecuting = true
        executeBlocks(startBlock.children) // 자식 블록들 실행 시작
    }

    // MARK: - 블록 리스트 순차 실행
    func executeBlocks(_ blocks: [Block], index: Int = 0) {
        // 모든 블록을 실행한 경우
        guard index < blocks.count else {
            print("✅ 모든 블록 실행 완료")
            // 모든 블록이 끝났는데 도착 타일(2)이 아니면 실패 처리
            if mapData[characterPosition.row][characterPosition.col] != goalTile {
                // 목표 지점 도달 실패
                print("❌ 실패: 깃발에 도달하지 못함")
                resetToStart()
            } else {
                // 깃발 도착 성공
                print("🎉 성공: 깃발 도착!")
                showSuccessDialog = true // 성공 다이얼로그 띄우기
                isExecuting = false
            }
            return
        }

        // 현재 실행할 불록
        let current = blocks[index]
        print("▶️ 현재 실행 중인 블록: \(current.type)")

        // 블록 타입에 따른 동작 처리
        switch current.type {
        case .moveForward:
            // 앞으로 이동 후 다음 블록 실행
            moveForward {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.executeBlocks(blocks, index: index + 1)
                }
            }

        case .turnLeft:
            // 왼쪽 회전 후 다음 블록 실행
            characterDirection = characterDirection.turnedLeft()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }

        case .turnRight:
            // 오른족 회전 후 다음 블록 실행
            characterDirection = characterDirection.turnedRight()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }

        default:
            // 실행 불가능한 블록은 건너뜀
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1)
            }
        }
    }

    // MARK: - 캐릭터 앞으로 이동
    func moveForward(completion: @escaping () -> Void) {
        var newRow = characterPosition.row
        var newCol = characterPosition.col

        // 방향에 따른 좌표 계산
        switch characterDirection {
        case .up: newRow -= 1
        case .down: newRow += 1
        case .left: newCol -= 1
        case .right: newCol += 1
        }

        // 맵 범위 내이고 이동 가능한 타일이면
        if newRow >= 0, newRow < mapData.count,
           newCol >= 0, newCol < mapData[0].count,
           mapData[newRow][newCol] != 0 {
            characterPosition = (newRow, newCol) // 위치 업데이트
            print("캐릭터 이동 → 위치: (\(newRow), \(newCol))")
            completion()
        } else {
            // 이동 실패 : 벽이거나 범위 밖일 경우
            print("이동 실패: 벽 또는 범위 밖입니다.")
            resetToStart()
        }
    }

    // MARK: - 실패 시 캐릭터 초기 위치로 되돌리기
    func resetToStart() {
        isExecuting = false
        characterPosition = initialPosition // 시작 위치로 초기화
        characterDirection = .right // 방향도 초기화
        showFailureDialog = true // 실패 다이얼로그 표시
        print("🔁 캐릭터를 시작 위치로 되돌림")
    }
    
    // MARK: - 다이얼로그 종료 후 상태 초기화
    func resetExecution() {
        isExecuting = false
        characterPosition = initialPosition // 위치 초기화
        characterDirection = .right // 방향 초기화
        print("🔄 다시하기: 캐릭터 초기화 및 다이얼로그 종료")
    }
}

