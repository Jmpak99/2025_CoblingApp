//
//  HomeViewModel.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var level: Int = 1
    @Published var exp: Double = 0
    @Published var expPercent: Double = 0.0   // 0.0 ~ 1.0

    // 미션 진행 상태
    @Published var dailyCount: Int = 0
    @Published var dailyIsCompleted: Bool = false
    @Published var monthlyCount: Int = 0
    @Published var monthlyIsCompleted: Bool = false

    // 미션 설정(missions 컬렉션) - DB 연동 값
    @Published var dailyIsEnabled: Bool = true
    @Published var dailyTitle: String = "오늘의 미션"
    @Published var dailySubtitle: String = "두 문제 이상 풀기"
    @Published var dailyTargetCount: Int = 2
    @Published var dailyRewardExp: Int = 120

    @Published var monthlyIsEnabled: Bool = true
    @Published var monthlyTitle: String = "월간 미션"
    @Published var monthlySubtitle: String = "1챕터 이상 끝내기"
    @Published var monthlyTargetCount: Int = 1
    @Published var monthlyRewardExp: Int = 400

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var isListening = false

    // missionProgress 리스너
    private var dailyListener: ListenerRegistration?
    private var monthlyListener: ListenerRegistration?

    // missions 설정 리스너
    private var dailyConfigListener: ListenerRegistration?
    private var monthlyConfigListener: ListenerRegistration?

    /// HomeView에서 onAppear에 호출 (중복 등록 방지)
    func startListeningUserData() {
        guard !isListening else { return }
        isListening = true

        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 유저 없음")
            isListening = false
            return
        }

        // ✅ users/{uid} 리스너 (레벨/exp)
        listener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error = error {
                print("❌ Firestore 불러오기 실패: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }

            let newLevel = data["level"] as? Int ?? 1

            // exp 타입 안전 처리 (Double/Int 둘 다 대응)
            let newExp: Double = {
                if let d = data["exp"] as? Double { return d }
                if let i = data["exp"] as? Int { return Double(i) }
                return 0
            }()

            self.level = newLevel
            self.exp = newExp

            let requiredExp = self.maxExpForLevel(newLevel)
            let raw = newExp / requiredExp
            self.expPercent = min(max(raw, 0.0), 1.0)
        }

        // missionProgress 리스너 시작
        startListeningMissionProgress(userId: userId)

        // missions 설정 리스너 시작
        startListeningMissionConfigs()
    }

    /// HomeView에서 onDisappear에 호출 (리스너 해제)
    func stopListeningUserData() {
        listener?.remove()
        listener = nil

        dailyListener?.remove()
        dailyListener = nil
        monthlyListener?.remove()
        monthlyListener = nil

        // missions 설정 리스너 해제
        dailyConfigListener?.remove()
        dailyConfigListener = nil
        monthlyConfigListener?.remove()
        monthlyConfigListener = nil

        isListening = false
    }

    // users/{uid}/missionProgress 리스닝
    private func startListeningMissionProgress(userId: String) {
        let base = db.collection("users").document(userId).collection("missionProgress")

        dailyListener = base.document("daily").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error = error {
                print("❌ daily missionProgress 불러오기 실패: \(error)")
                self.dailyCount = 0
                self.dailyIsCompleted = false
                return
            }

            guard let data = snapshot?.data() else {
                self.dailyCount = 0
                self.dailyIsCompleted = false
                return
            }

            self.dailyCount = data["count"] as? Int ?? 0
            self.dailyIsCompleted = data["isCompleted"] as? Bool ?? false
        }

        monthlyListener = base.document("monthly").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error = error {
                print("❌ monthly missionProgress 불러오기 실패: \(error)")
                self.monthlyCount = 0
                self.monthlyIsCompleted = false
                return
            }

            guard let data = snapshot?.data() else {
                self.monthlyCount = 0
                self.monthlyIsCompleted = false
                return
            }

            self.monthlyCount = data["count"] as? Int ?? 0
            self.monthlyIsCompleted = data["isCompleted"] as? Bool ?? false
        }
    }

    // missions/daily, missions/monthly 설정 리스닝
    private func startListeningMissionConfigs() {
        let missions = db.collection("missions")

        dailyConfigListener = missions.document("daily").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error = error {
                print("❌ missions/daily 불러오기 실패: \(error)")
                return // 실패 시 기존 기본값 유지
            }

            guard let data = snapshot?.data() else {
                return // 문서 없으면 기본값 유지
            }

            self.dailyIsEnabled = data["isEnabled"] as? Bool ?? true
            self.dailyTitle = data["title"] as? String ?? "오늘의 미션"
            self.dailySubtitle = data["subtitle"] as? String ?? "두 문제 이상 풀기"
            self.dailyTargetCount = data["targetCount"] as? Int ?? 2
            self.dailyRewardExp = data["rewardExp"] as? Int ?? 120
        }

        monthlyConfigListener = missions.document("monthly").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error = error {
                print("❌ missions/monthly 불러오기 실패: \(error)")
                return
            }

            guard let data = snapshot?.data() else {
                return
            }

            self.monthlyIsEnabled = data["isEnabled"] as? Bool ?? true
            self.monthlyTitle = data["title"] as? String ?? "월간 미션"
            self.monthlySubtitle = data["subtitle"] as? String ?? "1챕터 이상 끝내기"
            self.monthlyTargetCount = data["targetCount"] as? Int ?? 1
            self.monthlyRewardExp = data["rewardExp"] as? Int ?? 400
        }
    }

    // QuestViewModel과 동일 테이블
    private func maxExpForLevel(_ level: Int) -> Double {
        let table: [Int: Double] = [
            1: 100, 2: 120, 3: 160, 4: 200, 5: 240,
            6: 310, 7: 380, 8: 480, 9: 600, 10: 750,
            11: 930, 12: 1160, 13: 1460, 14: 1820, 15: 2270,
            16: 2840, 17: 3550, 18: 4440, 19: 5550
        ]
        return table[level] ?? 100
    }
}
