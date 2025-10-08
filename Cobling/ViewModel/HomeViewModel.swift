//
//  HomeViewModel.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var level: Int = 1
    @Published var exp: Int = 0
    @Published var expPercent: Double = 0.0   // 0.0 ~ 1.0
    
    private let db = Firestore.firestore()
    
    func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 유저 없음")
            return
        }
        
        db.collection("users").document(userId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Firestore 불러오기 실패: \(error)")
                return
            }
            guard let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self.level = data["level"] as? Int ?? 1
                self.exp = data["exp"] as? Int ?? 0
                
                // 레벨별 필요 EXP 곡선 (간단 버전: 100 + 20 * (level-1))
                let requiredExp = self.requiredExpForLevel(self.level)
                self.expPercent = Double(self.exp) / Double(requiredExp)
            }
        }
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
        // 필요시 계속 확장
        default: return 1000
        }
    }
}
