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
    
    // DB startDirection 값을 저장해두는 용도 (reset 시 이 값으로 복구)
    private var startDirection: Direction = .right
    
    @Published var mapData: [[Int]] = []         // Firestore에서 변환된 맵
    @Published var showFailureDialog = false
    @Published var showSuccessDialog = false
    @Published var startBlock = Block(type: .start)
    @Published var currentExecutingBlockID: UUID? = nil
    @Published var isExecuting = false
    @Published var didFailExecution = false
    
    // MARK: - Success Reward
    @Published var successReward: SuccessReward? = nil
    
    // - QuestDetailView 최초 진입 시 intro 1회
    // - 챕터 클리어 보상(2단 게이지) 끝난 뒤 outro 표시
    @Published var isShowingCutscene: Bool = false
    @Published var currentCutscene: ChapterCutscene? = nil
    
    // 보상 정산 중 오버레이 표시 여부
    @Published var isRewardLoading: Bool = false
    @Published var showRewardDelayAlert: Bool = false
    
    // MARK: - 적
    @Published private(set) var initialEnemies: [Enemy] = []
    @Published var enemies: [Enemy] = []

    // MARK: - Firestore
    @Published var subQuest: SubQuestDocument?   // 현재 불러온 퀘스트
    @Published private(set) var startPosition: (row: Int, col: Int) = (0, 0)
    @Published private(set) var goalPosition: (row: Int, col: Int) = (0, 0)
    @Published var allowedBlocks: [BlockType] = []
    
    // if 조건 옵션(스테이지별)
    @Published var currentAllowedIfConditions: [IfCondition] = IfCondition.allCases
    @Published var currentDefaultIfCondition: IfCondition = .frontIsClear

    private let db = Firestore.firestore()

    // fetch로 받은 식별자 저장 (클리어 시 progress 문서 지정에 사용)
    var currentChapterId: String = ""
    private var currentSubQuestId: String = ""

    // unlock 대기 리스너(중복 등록 방지)
    private var unlockListener: ListenerRegistration?
    
    // users 업데이트 감지 리스너 (보관 / 중복 제거용)
    private var userUpdateListener: ListenerRegistration?
    
    // 챕터 보너스 필드 반영 대기 리스너(레이스 해결용)
    private var chapterBonusListener: ListenerRegistration?
    
    // 보상 로딩 시작 시간(최소 표시 시간 보장용)
    private var rewardLoadingStartedAt: Date? = nil

    // 오버레이 최소 표시 시간 (0.3~0.6 사이로 조절)
    private let minRewardOverlayDuration: TimeInterval = 0.45

    deinit {
        unlockListener?.remove()
        userUpdateListener?.remove() // 누수 방지
        chapterBonusListener?.remove() // 챕터 보너스 리스너 누수 방지
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
        characterDirection = startDirection

        // ▶️ 적 상태 초기화
        enemies = initialEnemies

        // ▶️ 다이얼로그 초기화
        showFailureDialog = false
        showSuccessDialog = false
        successReward = nil
        
        // ▶️ 로딩 오버레이도 초기화
        isRewardLoading = false
        rewardLoadingStartedAt = nil
    }
    
    // =================================================
    // 컷신(인트로/아웃트로) "봤는지" 조회용 헬퍼
    // - QuestBlockView / SuccessDialogView에서 분기 처리할 때 사용
    // - LocalStorageManager 로직을 그대로 노출만 함
    // =================================================
    func wasCutsceneShown(chapterId: String, type: ChapterCutsceneType) -> Bool {
        LocalStorageManager.isCutsceneShown(chapterId: chapterId, type: type)
    }

    func wasOutroShown(chapterId: String) -> Bool {
        LocalStorageManager.isCutsceneShown(chapterId: chapterId, type: .outro)
    }
    
    // Chapter Cutscene Control
    // - intro: QuestDetailView 최초 진입에서 호출
    // - outro: 챕터 보상(2단 게이지) 끝난 뒤 호출
    func presentIntroIfNeeded(chapterId: String) {
        if LocalStorageManager.isCutsceneShown(chapterId: chapterId, type: .intro) {
            return
        }

        // ChapterDialogueStore에서 라인 가져오기
        let lines = ChapterDialogueStore.lines(chapterId: chapterId, type: .intro)

        // ChapterCutscene로 감싸기 (lines 비어있을 때 방어)
        guard !lines.isEmpty else { return }

        let cutscene = ChapterCutscene(
            chapterId: chapterId,
            type: .intro,
            lines: lines
        )

        DispatchQueue.main.async {
            self.currentCutscene = cutscene
            self.isShowingCutscene = true
        }
    }
    
    /// 정책 : 챕터 클리어 보상(2단 게이지) 끝난 뒤 호출
    func presentOutroAfterChapterReward(chapterId: String) {
        if LocalStorageManager.isCutsceneShown(chapterId: chapterId, type: .outro) {
            return
        }

        // ChapterDialogueStore에서 라인 가져오기
        let lines = ChapterDialogueStore.lines(chapterId: chapterId, type: .outro)

        guard !lines.isEmpty else { return }

        let cutscene = ChapterCutscene(
            chapterId: chapterId,
            type: .outro,
            lines: lines
        )

        DispatchQueue.main.async {
            self.currentCutscene = cutscene
            self.isShowingCutscene = true
        }
    }

    func dismissCutsceneAndMarkShown() {
        guard let cutscene = currentCutscene else {
            isShowingCutscene = false
            return
        }

        LocalStorageManager.setCutsceneShown(chapterId: cutscene.chapterId, type: cutscene.type)

        DispatchQueue.main.async {
            self.isShowingCutscene = false
            self.currentCutscene = nil
        }
    }
    
    // 보상 정산 로딩 시작 (오버레이 ON)
    private func beginRewardLoading() {
        DispatchQueue.main.async {
            self.rewardLoadingStartedAt = Date()
            self.isRewardLoading = true
        }
    }

    // 보상 정산 로딩 종료 + (성공 다이얼로그 표시를) 최소표시시간 이후 실행
    private func endRewardLoadingAndShowSuccess(_ showSuccess: @escaping () -> Void) {
        let started = rewardLoadingStartedAt ?? Date()
        let elapsed = Date().timeIntervalSince(started)
        let remaining = max(0, minRewardOverlayDuration - elapsed)

        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            self.isRewardLoading = false
            self.rewardLoadingStartedAt = nil
            showSuccess()
        }
    }
    
    // SubQuest rules에서 if 조건 옵션/기본값을 ViewModel에 반영
    private func applyIfRules(from subQuest: SubQuestDocument) {

        // 1) 허용 조건 리스트 (없으면 전체 허용)
        let allowedRaw = subQuest.rules.allowedIfConditions ?? []
        let allowed = allowedRaw.compactMap { IfCondition(rawValue: $0) }

        self.currentAllowedIfConditions = allowed.isEmpty ? IfCondition.allCases : allowed

        // 2) 기본 조건 (없거나 잘못된 값이면 frontIsClear)
        if let raw = subQuest.rules.defaultIfCondition,
           let cond = IfCondition(rawValue: raw) {
            self.currentDefaultIfCondition = cond
        } else {
            self.currentDefaultIfCondition = .frontIsClear
        }

        print("🟩 IF 룰 반영 완료",
              "allowed:", self.currentAllowedIfConditions.map { $0.rawValue },
              "default:", self.currentDefaultIfCondition.rawValue)
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

                            // 방향 초기화 + 시작 방향 저장
                            let dir = Direction(rawValue: subQuest.map.startDirection.lowercased()) ?? .right
                            self.startDirection = dir
                            self.characterDirection = dir

                            // 허용 블록 반영
                            self.allowedBlocks = subQuest.rules.allowBlocks.compactMap { BlockType(rawValue: $0) }
                            
                            // if 조건 룰(allowed/default) 반영
                            self.applyIfRules(from: subQuest)

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
        progressRef.getDocument(source: FirestoreSource.server) { [weak self] snap, error in
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
            // 잠깐 locked일 수 있으니 기다렸다가 열리면 진입
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

            // 다음 퀘스트도 서버 우선으로 읽기(캐시 locked 완화)
            progressRef.getDocument(source: FirestoreSource.server) { [weak self] snap, error in
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
    
    // MARK: - IF 조건 판정
    private func evaluateIfCondition(_ cond: IfCondition) -> Bool {
        switch cond {

        case .frontIsClear:
            return isFrontClear()

        case .frontIsBlocked:
            return !isFrontClear()

        case .enemyInFront:
            return isEnemyInFront()

        default:
            return false
        }
    }

    // MARK: - 앞칸이 이동 가능한지(벽/맵 범위 체크)
    private func isFrontClear() -> Bool {
        
        guard !mapData.isEmpty, !mapData[0].isEmpty else { return false }
        
        let (r, c) = characterPosition
        var nr = r
        var nc = c

        switch characterDirection {
        case .up: nr -= 1
        case .down: nr += 1
        case .left: nc -= 1
        case .right: nc += 1
        }

        // 범위
        guard nr >= 0, nr < mapData.count,
              nc >= 0, nc < mapData[0].count else { return false }

        // 벽(0)인지
        return mapData[nr][nc] != 0
    }

    // MARK: - 한 칸 앞에 적이 있는지
    private func isEnemyInFront() -> Bool {
        let (r, c) = characterPosition
        var nr = r
        var nc = c

        switch characterDirection {
        case .up: nr -= 1
        case .down: nr += 1
        case .left: nc -= 1
        case .right: nc += 1
        }

        return enemies.contains { $0.row == nr && $0.col == nc }
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
            
            // 실패 상태면 그냥 종료 (위로 전파 안 함)
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
            isExecuting = false
            
            // showSuccessDialog 여기서 켜지 않음 (reward 생성 후 켜야 함)
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

                    // 3. 내부 블록 실행
                    self.executeBlocks(current.children) {
                        runRepeat(remaining - 1)
                    }
                }
            }

            runRepeat(repeatCount)
            
        case .if:
            let condition = current.condition
            let shouldRun = evaluateIfCondition(condition)

            DispatchQueue.main.async {
                self.currentExecutingBlockID = current.id
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {

                if shouldRun {
                    // 조건 true → 내부 블록 실행
                    self.executeBlocks(current.children) {
                        self.executeBlocks(
                            blocks,
                            index: index + 1,
                            isTopLevel: isTopLevel,
                            completion: completion
                        )
                    }
                } else {
                    // 조건 false → 스킵
                    self.executeBlocks(
                        blocks,
                        index: index + 1,
                        isTopLevel: isTopLevel,
                        completion: completion
                    )
                }
            }

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
    
    // MARK: - target이 ancestor의 "자손(하위 컨테이너)"인지 판별
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
    
    // 보너스 exp를 로컬로 적용해서 (level, exp)를 계산하는 헬퍼 (users 반영 지연 대비 안전망)
    private func applyGainLocally(
        level: Int,
        exp: Double,
        gain: Int
    ) -> (level: Int, exp: Double) {
        var lv = level
        var e = exp + Double(max(0, gain))

        while e >= maxExpForLevel(lv) {
            e -= maxExpForLevel(lv)
            lv += 1
        }
        return (lv, e)
    }

    
    // MARK: - USERS 업데이트를 기다리는 헬퍼
    private func waitForUserUpdate(
        userRef: DocumentReference,
        previousLevel: Int,
        previousExp: Double,
        timeout: Double = 6.0,
        completion: @escaping (_ level: Int, _ exp: Double) -> Void,
        onTimeout: @escaping () -> Void
    ) {
        // 기존 리스너 제거 (중복 등록 방지)
        userUpdateListener?.remove()
        userUpdateListener = nil
        
        var done = false

        // 타임아웃
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self else { return }
            guard !done else { return }
            done = true
            self.userUpdateListener?.remove()
            self.userUpdateListener = nil
            onTimeout()
        }

        // listener를 userUpdateListener에 저장해서 관리
        userUpdateListener = userRef.addSnapshotListener { [weak self] snap, err in
            guard let self else { return }
            guard !done else { return }
            if let err = err {
                print("❌ waitForUserUpdate listener error:", err)
                return
            }
            guard let data = snap?.data() else { return }

            let level = data["level"] as? Int ?? 1
            let exp = data["exp"] as? Double ?? 0

            // (level, exp)가 이전과 달라졌으면 "정산 완료"로 간주
            if level != previousLevel || exp != previousExp {
                done = true
                self.userUpdateListener?.remove()
                self.userUpdateListener = nil
                completion(level, exp)
            }
        }
    }
    
    // 챕터 보너스 정보를 읽어오는 헬퍼
    // - 서버(index.js)에서 users/{uid}/progress/{chapterId} 문서에
    //   chapterBonusGranted / chapterBonusExp 를 저장해둔다고 가정
    private func fetchChapterBonusInfo(
        userId: String,
        chapterId: String,
        subQuestId: String,
        completion: @escaping (_ isCleared: Bool, _ bonusExp: Int) -> Void
    ) {
        let subQuestProgressRef = db.collection("users")
            .document(userId)
            .collection("progress")
            .document(chapterId)
            .collection("subQuests")
            .document(subQuestId)

        subQuestProgressRef.getDocument(source: FirestoreSource.server) { snap, _ in
            let data = snap?.data() ?? [:]

            let cleared = data["chapterClearGranted"] as? Bool ?? false

            let bonusExp =
                data["chapterBonusExpGranted"] as? Int
                ?? Int(data["chapterBonusExpGranted"] as? Double ?? 0)

            completion(cleared, bonusExp)
        }
    }
    
    // 챕터 보너스 필드가 "늦게 들어오는" 레이스 해결:
    // - users 문서(level/exp)가 먼저 갱신되고
    // - subQuest progress 문서의 chapterBonusExpGranted가 나중에 merge 될 수 있으므로
    // - 성공 다이얼로그 띄우기 직전에 이 필드가 들어올 때까지 잠깐 대기
    private func waitForChapterBonusWrite(
        userId: String,
        chapterId: String,
        subQuestId: String,
        timeout: Double = 2.0,
        completion: @escaping (_ isCleared: Bool, _ bonusExp: Int) -> Void
    ) {
        let ref = db.collection("users")
            .document(userId)
            .collection("progress")
            .document(chapterId)
            .collection("subQuests")
            .document(subQuestId)

        var done = false
        
        // 기존 챕터 보너스 리스너 제거(중복 등록/누수 방지)
        chapterBonusListener?.remove()
        chapterBonusListener = nil

        // 타임아웃: 끝까지 안 오면 현재 값으로 진행
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            guard let self else { return }
            guard !done else { return }
            done = true
            self.chapterBonusListener?.remove()
            self.chapterBonusListener = nil

            // 마지막으로 한번 읽고 종료
            ref.getDocument(source: FirestoreSource.server) { snap, _ in
                let data = snap?.data() ?? [:]
                let cleared = data["chapterClearGranted"] as? Bool ?? false
                let bonusExp =
                    data["chapterBonusExpGranted"] as? Int
                    ?? Int(data["chapterBonusExpGranted"] as? Double ?? 0)
                completion(cleared, bonusExp)
            }
        }

        // 리스너로 “필드가 생기는 순간”을 기다림
        chapterBonusListener = ref.addSnapshotListener { [weak self] snap, _ in
            guard let self else { return }
            guard !done else { return }
            let data = snap?.data() ?? [:]

            let cleared = data["chapterClearGranted"] as? Bool ?? false
            let bonusExp =
                data["chapterBonusExpGranted"] as? Int
                ?? Int(data["chapterBonusExpGranted"] as? Double ?? 0)

            // cleared가 true이거나 bonusExp가 0보다 커지면 “보너스 준비 완료”
            if cleared || bonusExp > 0 {
                done = true
                self.chapterBonusListener?.remove()
                self.chapterBonusListener = nil
                completion(cleared, bonusExp)
            }
        }
    }
    
    

    // MARK: - 퀘스트 클리어 처리
    private func handleQuestClear(subQuest: SubQuestDocument, usedBlocks: Int) {

        // 보상 정산 시작 오버레이 ON
        beginRewardLoading()

        let baseExp = subQuest.rewards.baseExp
        let bonusExp = subQuest.rewards.perfectBonusExp
        let maxSteps = subQuest.rules.maxSteps

        let isPerfect = usedBlocks <= maxSteps
        let earned = isPerfect ? (baseExp + bonusExp) : baseExp

        guard let userId = Auth.auth().currentUser?.uid else { return }
        let subId = currentSubQuestId
        guard !subId.isEmpty else { return }

        let progressRef = db.collection("users")
            .document(userId)
            .collection("progress")
            .document(currentChapterId)
            .collection("subQuests")
            .document(subId)

        let userRef = db.collection("users").document(userId)

        // 재도전(이미 completed)면 level/exp 변화가 없으니 기다리면 타임아웃이 정상
        progressRef.getDocument(source: FirestoreSource.server) { [weak self] progressSnap, _ in
            guard let self else { return }

            let prevState = progressSnap?.data()?["state"] as? String ?? "locked"

            // =================================================
            // 이미 완료된 퀘스트 재도전 케이스
            // =================================================
            if prevState == "completed" {

                // (선택) 재도전 기록만 남기고 싶으면 attempts만 증가
                progressRef.updateData([
                    "attempts": FieldValue.increment(Int64(1)),
                    "updatedAt": FieldValue.serverTimestamp()
                ])

                // users는 "현재 값"만 읽어서 reward 구성
                userRef.getDocument(source: FirestoreSource.server) { [weak self] userSnap, _ in
                    guard let self, let data = userSnap?.data() else { return }

                    let level = data["level"] as? Int ?? 1
                    let exp = data["exp"] as? Double ?? 0
                    let maxExp = self.maxExpForLevel(level)

                    // 챕터 보너스 정보도 함께 읽어오기
                    // (재도전이라도, UI에 "챕터 클리어됨" 표시가 필요할 수 있음)
                    self.fetchChapterBonusInfo(
                        userId: userId,
                        chapterId: self.currentChapterId,
                        subQuestId: subId
                    ) { isCleared, chapterBonus in

                        print(
                            "🟢 fetchChapterBonusInfo 결과",
                            "isCleared:", isCleared,
                            "bonus:", chapterBonus,
                            "chapter:", self.currentChapterId,
                            "subId:", subId
                        )

                        DispatchQueue.main.async {
                            self.successReward = SuccessReward(
                                level: level,
                                currentExp: CGFloat(exp),
                                maxExp: CGFloat(maxExp),
                                gainedExp: 0,
                                isPerfectClear: false,
                                chapterBonusExp: chapterBonus,
                                isChapterCleared: isCleared
                            )
                        }

                        // 최소 표시시간 보장 후 오버레이 OFF → 성공 다이얼로그 ON
                        self.endRewardLoadingAndShowSuccess {
                            self.showSuccessDialog = true
                        }
                    }
                }

                return
            }

            // =================================================
            // 처음 완료(보상 지급) 케이스
            // =================================================

            // 0) 현재 level/exp를 먼저 읽어둠 (변경 감지 기준)
            userRef.getDocument { [weak self] userSnap, _ in
                guard let self else { return }
                let prevLevel = userSnap?.data()?["level"] as? Int ?? 1
                let prevExp = userSnap?.data()?["exp"] as? Double ?? 0

                // 1) progress 업데이트 (Cloud Function 트리거)
                progressRef.updateData([
                    "earnedExp": earned,
                    "perfectClear": isPerfect,
                    "state": "completed",
                    "attempts": FieldValue.increment(Int64(1)),
                    "updatedAt": FieldValue.serverTimestamp()
                ])

                // 2) users 문서가 실제로 갱신될 때까지 기다렸다가 reward 생성
                self.waitForUserUpdate(
                    userRef: userRef,
                    previousLevel: prevLevel,
                    previousExp: prevExp,
                    timeout: 6.0,
                    completion: { [weak self] level, exp in
                        guard let self else { return }

                        // 🔧 [수정] 여기의 level/exp는 "서브퀘스트 보상" 반영분일 수 있으므로 보관
                        let afterSubquestLevel = level
                        let afterSubquestExp = exp

                        // 🔧 [수정] 보너스 필드가 써질 때까지 잠깐 기다림
                        self.waitForChapterBonusWrite(
                            userId: userId,
                            chapterId: self.currentChapterId,
                            subQuestId: subId,
                            timeout: 2.0
                        ) { [weak self] isCleared, chapterBonus in
                            guard let self else { return }

                            print("🟣 waitForChapterBonusWrite 결과",
                                  "isCleared:", isCleared,
                                  "bonus:", chapterBonus)

                            // 🔧 [수정] 보너스가 없으면(또는 cleared 아님) 그냥 1단계 값으로 표시
                            guard isCleared, chapterBonus > 0 else {
                                let maxExp = self.maxExpForLevel(afterSubquestLevel)
                                DispatchQueue.main.async {
                                    self.successReward = SuccessReward(
                                        level: afterSubquestLevel,
                                        currentExp: CGFloat(afterSubquestExp),
                                        maxExp: CGFloat(maxExp),
                                        gainedExp: earned,
                                        isPerfectClear: isPerfect,
                                        chapterBonusExp: 0,
                                        isChapterCleared: false
                                    )
                                }
                                self.endRewardLoadingAndShowSuccess {
                                    self.showSuccessDialog = true
                                }
                                return
                            }

                            // 보너스가 users에 반영될 때까지 "한 번 더" users 업데이트를 기다림
                            self.waitForUserUpdate(
                                userRef: userRef,
                                previousLevel: afterSubquestLevel,
                                previousExp: afterSubquestExp,
                                timeout: 2.5,
                                completion: { [weak self] finalLevel, finalExp in
                                    guard let self else { return }
                                    let maxExp = self.maxExpForLevel(finalLevel)

                                    DispatchQueue.main.async {
                                        self.successReward = SuccessReward(
                                            level: finalLevel,
                                            currentExp: CGFloat(finalExp),
                                            maxExp: CGFloat(maxExp),
                                            gainedExp: earned,              // 1단계(서브퀘스트)
                                            isPerfectClear: isPerfect,
                                            chapterBonusExp: chapterBonus,  // 2단계(챕터 보너스)
                                            isChapterCleared: true
                                        )
                                    }

                                    self.endRewardLoadingAndShowSuccess {
                                        self.showSuccessDialog = true
                                    }
                                },
                                onTimeout: { [weak self] in
                                    guard let self else { return }

                                    // users 반영이 늦으면 로컬 계산으로 보정(안전망)
                                    let applied = self.applyGainLocally(
                                        level: afterSubquestLevel,
                                        exp: afterSubquestExp,
                                        gain: chapterBonus
                                    )
                                    let maxExp = self.maxExpForLevel(applied.level)

                                    print("🟠 users 보너스 반영 대기 timeout → 로컬 보정 적용",
                                          "level:", applied.level,
                                          "exp:", applied.exp,
                                          "bonus:", chapterBonus)

                                    DispatchQueue.main.async {
                                        self.successReward = SuccessReward(
                                            level: applied.level,
                                            currentExp: CGFloat(applied.exp),
                                            maxExp: CGFloat(maxExp),
                                            gainedExp: earned,
                                            isPerfectClear: isPerfect,
                                            chapterBonusExp: chapterBonus,
                                            isChapterCleared: true
                                        )
                                    }

                                    self.endRewardLoadingAndShowSuccess {
                                        self.showSuccessDialog = true
                                    }
                                }
                            )
                        }
                    },
                    onTimeout: { [weak self] in
                        guard let self else { return }
                        print("⚠️ users update wait timeout → fallback getDocument")

                        userRef.getDocument(source: FirestoreSource.server) { [weak self] snap, _ in
                            guard let self, let data = snap?.data() else { return }
                            let level = data["level"] as? Int ?? 1
                            let exp = data["exp"] as? Double ?? 0
                            let maxExp = self.maxExpForLevel(level)

                            // timeout fallback에서도 챕터 보너스 정보 읽기
                            self.fetchChapterBonusInfo(
                                userId: userId,
                                chapterId: self.currentChapterId,
                                subQuestId: subId
                            ) { isCleared, chapterBonus in
                                DispatchQueue.main.async {
                                    self.successReward = SuccessReward(
                                        level: level,
                                        currentExp: CGFloat(exp),
                                        maxExp: CGFloat(maxExp),
                                        gainedExp: earned,
                                        isPerfectClear: isPerfect,
                                        chapterBonusExp: chapterBonus,
                                        isChapterCleared: isCleared
                                    )
                                }

                                // 최소 표시시간 보장 후 오버레이 OFF → 성공 다이얼로그 ON
                                self.endRewardLoadingAndShowSuccess {
                                    self.showSuccessDialog = true
                                }
                            }
                        }
                    }
                )
            }
        }
    }


    
    private func countUsedBlocks() -> Int {
        func dfs(_ blocks: [Block]) -> Int {
            var total = 0
            for b in blocks {
                total += 1
                if b.type.isContainer {
                    total += dfs(b.children)
                }
            }
            return total
        }
        return dfs(startBlock.children)
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
    
    // MARK: - 공격 처리 (가장 가까운 1명 처치)
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
            self.characterDirection = self.startDirection
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
        characterDirection = startDirection
        
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
