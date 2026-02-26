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

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var isListening = false

    /// HomeView에서 onAppear에 호출 (중복 등록 방지)
    func startListeningUserData() {
        guard !isListening else { return }
        isListening = true

        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 유저 없음")
            isListening = false
            return
        }

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
    }

    /// HomeView에서 onDisappear에 호출 (리스너 해제)
    func stopListeningUserData() {
        listener?.remove()
        listener = nil
        isListening = false
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
