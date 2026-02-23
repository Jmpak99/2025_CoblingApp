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
    @Published var exp: Int = 0
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
            let newExp = data["exp"] as? Int ?? 0

            self.level = newLevel
            self.exp = newExp

            let requiredExp = self.requiredExpForLevel(newLevel)
            let raw = Double(newExp) / Double(requiredExp)
            self.expPercent = min(max(raw, 0.0), 1.0)
        }
    }

    /// HomeView에서 onDisappear에 호출 (리스너 해제)
    func stopListeningUserData() {
        listener?.remove()
        listener = nil
        isListening = false
    }

    private func requiredExpForLevel(_ level: Int) -> Int {
        switch level {
        case 1: return 100
        case 2: return 120
        case 3: return 160
        case 4: return 200
        case 5: return 240
        case 6: return 310
        case 7: return 380
        case 8: return 480
        case 9: return 600
        case 10: return 750
        default: return 1000
        }
    }
}
