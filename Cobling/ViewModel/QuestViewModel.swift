//
//  QuestViewModel.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - 캐릭터 방향 열거형 정의
enum Direction: String, Codable {
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

// MARK: - 퀘스트 실행 뷰모델
class QuestViewModel: ObservableObject {
    // 🔹 게임 실행 상태
    @Published var characterPosition: (row: Int, col: Int) = (0, 0)
    @Published var characterDirection: Direction = .right
    @Published var mapData: [[Int]] = []         // Firestore에서 변환된 맵
    @Published var showFailureDialog = false
    @Published var showSuccessDialog = false
    @Published var startBlock = Block(type: .start)
    @Published var currentExecutingBlockID: UUID? = nil
    @Published var isExecuting = false
    
    // 🔹 Firestore 데이터
    @Published var subQuest: SubQuestDocument?   // 현재 불러온 퀘스트
    
    // 🔹 시작/목표 좌표 (외부에서 읽기만 가능)
    @Published private(set) var startPosition: (row: Int, col: Int) = (0, 0)
    @Published private(set) var goalPosition: (row: Int, col: Int) = (0, 0)
    
    private let db = Firestore.firestore()
    
    // MARK: - Firestore에서 SubQuest 불러오기
    func fetchSubQuest(chapterId: String, subQuestId: String) {
        db.collection("quests")
            .document(chapterId)
            .collection("subQuests")
            .document(subQuestId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("❌ Firestore 불러오기 실패: \(error)")
                    return
                }
                
                do {
                    if let subQuest = try snapshot?.data(as: SubQuestDocument.self) {
                        DispatchQueue.main.async {
                            self.subQuest = subQuest
                            
                            // 맵 데이터 (grid는 길만 0/1)
                            self.mapData = subQuest.map.parsedGrid
                            
                            // 시작/목표 위치 Firestore 필드 사용
                            self.startPosition = (subQuest.map.start.row, subQuest.map.start.col)
                            self.goalPosition = (subQuest.map.goal.row, subQuest.map.goal.col)
                            
                            // 캐릭터 위치 초기화
                            self.characterPosition = self.startPosition
                            
                            // 방향 초기화
                            self.characterDirection = Direction(
                                rawValue: subQuest.map.startDirection.lowercased()
                            ) ?? .right
                            
                            print("✅ 불러온 서브퀘스트: \(subQuest.title)")
                        }
                    }
                } catch {
                    print("❌ 디코딩 실패: \(error)")
                }
            }
    }
    
    // MARK: - 블록 실행 시작
    func startExecution() {
        guard !isExecuting else { return }
        isExecuting = true
        executeBlocks(startBlock.children)
    }

    // MARK: - 블록 리스트 순차 실행
    func executeBlocks(_ blocks: [Block], index: Int = 0) {
        guard index < blocks.count else {
            print("✅ 모든 블록 실행 완료")
            // 도착 지점 검사
            if characterPosition != goalPosition {
                print("❌ 실패: 깃발에 도달하지 못함")
                resetToStart()
            } else {
                print("🎉 성공: 깃발 도착!")
                showSuccessDialog = true
                isExecuting = false
            }
            return
        }
        
        let current = blocks[index]
        currentExecutingBlockID = current.id
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
    
    // MARK: - 앞으로 이동
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
            print("캐릭터 이동 → 위치: (\(newRow), \(newCol))")
            completion()
        } else {
            print("이동 실패: 벽 또는 범위 밖입니다.")
            resetToStart()
        }
    }
    
    // MARK: - 실패 시 초기화
    func resetToStart() {
        isExecuting = false
        currentExecutingBlockID = nil
        characterPosition = startPosition
        characterDirection = .right
        showFailureDialog = true
        print("🔁 캐릭터를 시작 위치로 되돌림")
    }
    
    func resetExecution() {
        isExecuting = false
        currentExecutingBlockID = nil
        characterPosition = startPosition
        characterDirection = .right
        print("🔄 다시하기: 캐릭터 초기화 및 다이얼로그 종료")
    }
}

#if DEBUG
// MARK: - Preview 설정 전용
extension QuestViewModel {
    func previewConfigure(
        map: [[Int]],
        start: (row: Int, col: Int),
        goal: (row: Int, col: Int),
        direction: Direction = .right
    ) {
        self.mapData = map
        self.startPosition = start
        self.goalPosition = goal
        self.characterPosition = start
        self.characterDirection = direction
    }
}
#endif
