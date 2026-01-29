//
//  QuestViewModel.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
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

// MARK: - 다음 퀘스트 이동 액션 정의
enum NextQuestAction {
    case goToQuest(String)   // 다음 퀘스트 ID (혹은 현재 ID)
    case locked              // 진짜 잠김 (선행 조건 미충족)
    case waiting             // 서버 해금 반영 대기(타임아웃)
    case goToList
}

// MARK: - 퀘스트 실행 뷰모델
final class QuestViewModel: ObservableObject {
    // MARK: - 게임 상태
    @Published var characterPosition: (row: Int, col: Int) = (0, 0)
    @Published var characterDirection: Direction = .right
    @Published var mapData: [[Int]] = []         // Firestore에서 변환된 맵
    @Published var showFailureDialog = false
    @Published var showSuccessDialog = false
    @Published var startBlock = Block(type: .start)
    @Published var currentExecutingBlockID: UUID? = nil
    @Published var isExecuting = false
    @Published var didFailExecution = false
    
    // MARK: - Success Reward
    @Published var successReward: SuccessReward? = nil
    
    // MARK: - 적
    @Published private(set) var initialEnemies: [Enemy] = []
    @Published var enemies: [Enemy] = []

    // MARK: - Firestore
    @Published var subQuest: SubQuestDocument?   // 현재 불러온 퀘스트
    @Published private(set) var startPosition: (row: Int, col: Int) = (0, 0)
    @Published private(set) var goalPosition: (row: Int, col: Int) = (0, 0)
    @Published var allowedBlocks: [BlockType] = []

    private let db = Firestore.firestore()

    // ✅ fetch로 받은 식별자 저장 (클리어 시 progress 문서 지정에 사용)
    var currentChapterId: String = ""
    private var currentSubQuestId: String = ""

    // ✅ unlock 대기 리스너(중복 등록 방지)
    private var unlockListener: ListenerRegistration?

    deinit {
        unlockListener?.remove()
    }
    
    func resetForNewSubQuest() {

        print("🧹 resetForNewSubQuest() 호출")

        // ▶️ 블록 트리 초기화
        startBlock = Block(type: .start)

        // ▶️ 실행 상태 초기화
        isExecuting = false
        didFailExecution = false
        currentExecutingBlockID = nil

        // ▶️ 캐릭터 상태 초기화
        characterPosition = startPosition
        characterDirection = .right

        // ▶️ 적 상태 초기화
        enemies = initialEnemies

        // ▶️ 다이얼로그 초기화
        showFailureDialog = false
        showSuccessDialog = false
        successReward = nil
    }
    
    // MARK: - Firestore에서 SubQuest 불러오기
    func fetchSubQuest(chapterId: String, subQuestId: String) {
        // 현재 컨텍스트 보관
        self.currentChapterId = chapterId
        self.currentSubQuestId = subQuestId

        db.collection("quests")
            .document(chapterId)
            .collection("subQuests")
            .document(subQuestId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Firestore 불러오기 실패: \(error)")
                    return
                }

                do {
                    if let subQuest = try snapshot?.data(as: SubQuestDocument.self) {
                        DispatchQueue.main.async {
                            self.subQuest = subQuest

                            // 맵 데이터
                            self.mapData = subQuest.map.parsedGrid

                            // 시작/목표 위치
                            self.startPosition = (subQuest.map.start.row, subQuest.map.start.col)
                            self.goalPosition = (subQuest.map.goal.row, subQuest.map.goal.col)
                            
                            // 적 목록 로드 (원본저장 + 현재 값 세팅)
                            let loadedEnemies = (subQuest.map.enemies ?? []).filter {
                                !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            }
                            
                            self.initialEnemies = loadedEnemies
                            self.enemies = loadedEnemies

                            // 캐릭터 위치 초기화
                            self.characterPosition = self.startPosition

                            // 방향 초기화
                            self.characterDirection = Direction(
                                rawValue: subQuest.map.startDirection.lowercased()
                            ) ?? .right

                            // 허용 블록 반영
                            self.allowedBlocks = subQuest.rules.allowBlocks.compactMap { BlockType(rawValue: $0) }

                            print("✅ 불러온 서브퀘스트: \(subQuest.title)")
                            print("📦 허용 블록: \(self.allowedBlocks)")
                        }
                    }
                } catch {
                    print("❌ 디코딩 실패: \(error)")
                }
            }
    }

    // MARK: - (공통) locked → inProgress/completed 될 때까지 대기
    private func waitUntilUnlocked(
        progressRef: DocumentReference,
        timeoutSeconds: Double = 4.0,
        onUnlocked: @escaping () -> Void,
        onTimeout: @escaping () -> Void
    ) {
        unlockListener?.remove()
        var done = false

        // 타임아웃 (무한 대기 방지)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds) { [weak self] in
            guard let self = self else { return }
            guard !done else { return }
            done = true
            self.unlockListener?.remove()
            self.unlockListener = nil
            onTimeout()
        }

        unlockListener = progressRef.addSnapshotListener { [weak self] snap, err in
            guard let self = self else { return }
            guard !done else { return }

            if let err = err {
                print("❌ unlock listener error:", err)
                return
            }

            let state = snap?.data()?["state"] as? String ?? "locked"

            if state == "inProgress" || state == "completed" {
                done = true
                self.unlockListener?.remove()
                self.unlockListener = nil
                onUnlocked()
            }
        }
    }

    // MARK: - 퀘스트 "진입" 게이트
    //  - 화면 진입 시 progress가 잠깐 locked로 보일 수 있으므로
    //    서버 반영까지 기다렸다가 들어가게 만드는 용도
    func ensureSubQuestAccessible(
        chapterId: String,
        subQuestId: String,
        timeoutSeconds: Double = 4.0,
        completion: @escaping (NextQuestAction) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.locked)
            return
        }

        let progressRef = db.collection("users")
            .document(userId)
            .collection("progress")
            .document(chapterId)
            .collection("subQuests")
            .document(subQuestId)

        // 서버 우선으로 읽어서 "캐시 locked" 오판 줄이기
        progressRef.getDocument(source: .server) { [weak self] snap, error in
            guard let self = self else { return }

            // 서버 read 실패(오프라인 등)면 캐시로 fallback
            if let _ = error, snap == nil {
                progressRef.getDocument { [weak self] snap2, _ in
                    guard let self = self else { return }
                    let state2 = snap2?.data()?["state"] as? String ?? "locked"
                    self.handleAccessState(
                        state: state2,
                        progressRef: progressRef,
                        subQuestId: subQuestId,
                        timeoutSeconds: timeoutSeconds,
                        completion: completion
                    )
                }
                return
            }

            let state = snap?.data()?["state"] as? String ?? "locked"
            self.handleAccessState(
                state: state,
                progressRef: progressRef,
                subQuestId: subQuestId,
                timeoutSeconds: timeoutSeconds,
                completion: completion
            )
        }
    }

    private func handleAccessState(
        state: String,
        progressRef: DocumentReference,
        subQuestId: String,
        timeoutSeconds: Double,
        completion: @escaping (NextQuestAction) -> Void
    ) {
        switch state {
        case "inProgress", "completed":
            completion(.goToQuest(subQuestId))

        case "locked":
            // ✅ 잠깐 locked일 수 있으니 기다렸다가 열리면 진입
            self.waitUntilUnlocked(
                progressRef: progressRef,
                timeoutSeconds: timeoutSeconds,
                onUnlocked: { completion(.goToQuest(subQuestId)) },
                onTimeout: { completion(.waiting) }
            )

        default:
            completion(.locked)
        }
    }

    // MARK: - 다음 퀘스트 찾기 로직 (locked면 waiting 대기)
    func goToNextSubQuest(completion: @escaping (NextQuestAction) -> Void) {
        guard let subQuest = subQuest else {
            completion(.goToList)
            return
        }

        let nextOrder = subQuest.order + 1
        let chapterRef = db.collection("quests")
            .document(currentChapterId)
            .collection("subQuests")

        chapterRef.whereField("order", isEqualTo: nextOrder).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching next subQuest: \(error)")
                completion(.goToList)
                return
            }

            guard let doc = snapshot?.documents.first else {
                print("📋 다음 퀘스트 없음 → 리스트로")
                completion(.goToList)
                return
            }

            let nextId = doc.documentID

            guard let userId = Auth.auth().currentUser?.uid else {
                print("❌ 로그인 유저 없음")
                completion(.locked)
                return
            }

            let progressRef = self.db.collection("users")
                .document(userId)
                .collection("progress")
                .document(self.currentChapterId)
                .collection("subQuests")
                .document(nextId)

            // ✅ 다음 퀘스트도 서버 우선으로 읽기(캐시 locked 완화)
            progressRef.getDocument(source: .server) { [weak self] snap, error in
                guard let self = self else { return }

                // 서버 read 실패면 캐시 fallback
                if let _ = error, snap == nil {
                    progressRef.getDocument { [weak self] snap2, _ in
                        guard let self = self else { return }
                        let state2 = snap2?.data()?["state"] as? String ?? "locked"
                        self.handleNextState(
                            state: state2,
                            progressRef: progressRef,
                            nextId: nextId,
                            completion: completion
                        )
                    }
                    return
                }

                let state = snap?.data()?["state"] as? String ?? "locked"
                self.handleNextState(
                    state: state,
                    progressRef: progressRef,
                    nextId: nextId,
                    completion: completion
                )
            }
        }
    }

    private func handleNextState(
        state: String,
        progressRef: DocumentReference,
        nextId: String,
        completion: @escaping (NextQuestAction) -> Void
    ) {
        switch state {
        case "inProgress", "completed":
            completion(.goToQuest(nextId))

        case "locked":
            self.waitUntilUnlocked(
                progressRef: progressRef,
                timeoutSeconds: 4.0,
                onUnlocked: { completion(.goToQuest(nextId)) },
                onTimeout: { completion(.waiting) }
            )

        default:
            completion(.locked)
        }
    }

    // MARK: - 블록 실행 시작
    func startExecution() {
        guard !isExecuting else { return }
        
        didFailExecution = false
        isExecuting = true

        executeBlocks(startBlock.children, isTopLevel: true) {
            // 최상위 실행 종료 (여기서는 아무것도 안 해도 됨)
        }
    }

    // MARK: - 블록 리스트 순차 실행
    func executeBlocks(
        _ blocks: [Block],
        index: Int = 0,
        isTopLevel: Bool = false,
        completion: @escaping () -> Void)
    {
        
        // 실패 시 즉시 중단
        guard !didFailExecution else {
            print("실행 중단 : 실패 상태")
            return
        }
        
        
        guard index < blocks.count else {
            
            if !isTopLevel {
                completion()
                return
            }
            
            // 🔴 실패 상태면 그냥 종료 (위로 전파 안 함)
                if didFailExecution {
                    return
                }
            
            print("✅ 모든 블록 실행 완료")

            // 도착 지점 검사
            if characterPosition != goalPosition {
                print("실패 : 깃발에 도달하지 못함")
                resetToStart()
                return
            }
            
            // 적이 하나라도 남아있으면 실패
            if !enemies.isEmpty {
                print("실패 : 적을 모두 처치하지 않음")
                resetToStart()
                return
            }
            
            // 성공 (깃발 + 적 전부 처치)
            print("성공 : 깃발 도착 + 적 전부 처치")
            showSuccessDialog = true
            isExecuting = false
            
            if let subQuest = subQuest {
                handleQuestClear(subQuest: subQuest, usedBlocks: countUsedBlocks())
            }
            
            completion()
            return
        }

        let current = blocks[index]
        currentExecutingBlockID = current.id
        print("▶️ 현재 실행 중인 블록: \(current.type)")

        switch current.type {
        case .moveForward:
            moveForward {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.executeBlocks(
                        blocks,
                        index: index + 1,
                        isTopLevel: isTopLevel,
                        completion: completion
                    )
                }
            }

        case .turnLeft:
            characterDirection = characterDirection.turnedLeft()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(
                    blocks,
                    index: index + 1,
                    isTopLevel: isTopLevel,
                    completion: completion
                )
            }

        case .turnRight:
            characterDirection = characterDirection.turnedRight()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(
                    blocks,
                    index: index + 1,
                    isTopLevel: isTopLevel,
                    completion: completion
                )
            }
            
        case .attack:
            attack {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.executeBlocks(
                        blocks,
                        index: index + 1,
                        isTopLevel: isTopLevel,
                        completion: completion
                    )
                    
                }
            }
            
        case .repeatCount:
            let repeatCount = Int(current.value ?? "1") ?? 1

            func runRepeat(_ remaining: Int) {
                // 반복문 종료 시점
                if remaining <= 0 {
                    // 다음 블럭으로 진행
                    self.executeBlocks(
                        blocks,
                        index: index + 1,
                        isTopLevel: isTopLevel,
                        completion: completion
                    )
                    return
                }

                // 1. 반복문 블록 강조
                DispatchQueue.main.async {
                    self.currentExecutingBlockID = current.id
                }

                // 2. 잠깐 깜빡이게 딜레이
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {

                    // ⭐ 3. 내부 블록 실행
                    self.executeBlocks(current.children) {
                        runRepeat(remaining - 1)
                    }
                }
            }

            runRepeat(repeatCount)

        default:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.executeBlocks(blocks, index: index + 1, completion: completion)
            }
        }
    }
    
    func findParentContainer(of target: Block) -> Block? {
        func search(in container: Block) -> Block? {
            if container.children.contains(where: { $0.id == target.id }) {
                return container
            }

            for child in container.children {
                if child.type.isContainer {
                    if let found = search(in: child) {
                        return found
                    }
                }
            }
            return nil
        }

        return search(in: startBlock)
    }
    
    // MARK: - ✅ target이 ancestor의 "자손(하위 컨테이너)"인지 판별
    func isDescendant(_ target: Block, of ancestor: Block) -> Bool {
        // ancestor 아래를 DFS로 탐색해서 target이 나오면 true
        func dfs(_ node: Block) -> Bool {
            for child in node.children {
                if child.id == target.id { return true }
                if child.type.isContainer {
                    if dfs(child) { return true }
                }
            }
            return false
        }

        return dfs(ancestor)
    }
    
    // MARK: - EXP 테이블 (서버와 동일)
    func maxExpForLevel(_ level: Int) -> Double {
        let table: [Int: Double] = [
            1: 100, 2: 120, 3: 160, 4: 200, 5: 240,
            6: 310, 7: 380, 8: 480, 9: 600, 10: 750,
            11: 930, 12: 1160, 13: 1460, 14: 1820, 15: 2270,
            16: 2840, 17: 3550, 18: 4440, 19: 5550
        ]
        return table[level] ?? 100
    }
    
    
    // MARK: - 퀘스트 클리어 처리
    private func handleQuestClear(subQuest: SubQuestDocument, usedBlocks: Int) {

        let baseExp = subQuest.rewards.baseExp
        let bonusExp = subQuest.rewards.perfectBonusExp
        let maxSteps = subQuest.rules.maxSteps

        let isPerfect = usedBlocks <= maxSteps
        let earned = isPerfect ? (baseExp + bonusExp) : baseExp

        guard let userId = Auth.auth().currentUser?.uid else { return }
        let subId = currentSubQuestId
        guard !subId.isEmpty else { return }

        // ===============================
        // 1️⃣ 서브퀘스트 progress 업데이트
        // ===============================
        let progressRef = db.collection("users")
            .document(userId)
            .collection("progress")
            .document(currentChapterId)
            .collection("subQuests")
            .document(subId)

        progressRef.updateData([
            "earnedExp": earned,
            "perfectClear": isPerfect,
            "state": "completed",
            "attempts": FieldValue.increment(Int64(1)),
            "updatedAt": FieldValue.serverTimestamp()
        ])

        // ===============================
        // 2️⃣ 서버 반영 후 유저 정보 다시 읽기
        // ===============================
        let userRef = db.collection("users").document(userId)

        // ⏱️ Cloud Function 반영 대기
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            userRef.getDocument { [weak self] snap, error in
                guard let self = self else { return }
                guard let data = snap?.data() else { return }

                let level = data["level"] as? Int ?? 1
                let currentExp = data["exp"] as? Double ?? 0
                let maxExp = self.maxExpForLevel(level)

                // ===============================
                // 3️⃣ SuccessReward (서버 기준!)
                // ===============================
                DispatchQueue.main.async {
                    self.successReward = SuccessReward(
                        level: level,
                        currentExp: CGFloat(currentExp),
                        maxExp: CGFloat(maxExp),
                        gainedExp: earned,
                        isPerfectClear: isPerfect
                    )

                    self.showSuccessDialog = true
                }
            }
        }
    }

    private func countUsedBlocks() -> Int {
        return startBlock.children.count
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

        // 1) 범위 체크
        guard newRow >= 0, newRow < mapData.count,
              newCol >= 0, newCol < mapData[0].count else {
            print("이동 실패: 범위 밖입니다.")
            resetToStart()
            return
        }

        // 2) 벽(0) 체크
        guard mapData[newRow][newCol] != 0 else {
            print("이동 실패: 벽입니다.")
            resetToStart()
            return
        }

        // 3) 적 충돌 체크 (부딪히면 실패)
        let hitEnemy = enemies.contains { $0.row == newRow && $0.col == newCol }
        if hitEnemy {
            print("💥 실패: 적과 충돌했습니다. (\(newRow), \(newCol))")
            resetToStart()
            return
        }

        // 4) 이동 성공
        characterPosition = (newRow, newCol)
        print("캐릭터 이동 → 위치: (\(newRow), \(newCol))")
        completion()
    }
    
    // MARK: - ✅ 공격 처리 (가장 가까운 1명 처치)
    func attack(completion: @escaping () -> Void) {
        guard let target = enemyInAttackRange() else {
            print("공격: 범위 내 적 없음")
            completion()
            return
        }

        // 현재는 '처치' = enemies에서 제거
        enemies.removeAll { $0.id == target.id }
        print("적 처치 성공: \(target.id) at (\(target.row), \(target.col))")

        completion()
    }
    
    // MARK: - 공격 범위 내 적 찾기 (가장 가까운 1명)
    func enemyInAttackRange() -> Enemy? {
        guard let subQuest = subQuest else { return nil }
        let range = max(0, subQuest.rules.attackRange)
        if range == 0 { return nil }

        let (row, col) = characterPosition

        for step in 1...range {
            var targetRow = row
            var targetCol = col

            switch characterDirection {
            case .up:    targetRow -= step
            case .down:  targetRow += step
            case .left:  targetCol -= step
            case .right: targetCol += step
            }

            if let enemy = enemies.first(where: { $0.row == targetRow && $0.col == targetCol }) {
                return enemy
            }
        }
        return nil
    }
        
        
    // MARK: - 실패 시 초기화
    func resetToStart() {
        DispatchQueue.main.async {
            self.didFailExecution = true
            self.isExecuting = false
            self.currentExecutingBlockID = nil
            self.characterPosition = self.startPosition
            self.characterDirection = .right
            self.enemies = self.initialEnemies
            self.showFailureDialog = true
            print("🔁 캐릭터를 시작 위치로 되돌림")
        }
    }

    func resetExecution() {
        didFailExecution = false
        isExecuting = false
        currentExecutingBlockID = nil
        characterPosition = startPosition
        characterDirection = .right
        
        enemies = initialEnemies
        
        print("🔄 다시하기: 캐릭터 초기화 및 다이얼로그 종료")
    }
}

    
#if DEBUG
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

// MARK: - Story / Hint (UI 전용 접근자)
extension QuestViewModel {

    var storyMessage: String? {
        guard let story = subQuest?.story,
              story.isActive else { return nil }
        return story.message
    }

    var hintMessage: String? {
        guard let hint = subQuest?.hint,
              hint.isActive else { return nil }
        return hint.message
    }
}

#endif
