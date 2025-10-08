//
//  ExpManager.swift
//  Cobling
//
//  Created by 박종민 on 2025/10/08.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ExpManager {
    // 레벨업 필요 경험치 테이블
    static let levelUpTable: [Int: Int] = [
        1: 100, 2: 120, 3: 160, 4: 200, 5: 240,
        6: 310, 7: 380, 8: 480, 9: 600, 10: 750,
        11: 930, 12: 1160, 13: 1460, 14: 1820,
        15: 2270, 16: 2840, 17: 3550, 18: 4440, 19: 5550
    ]
    
    /// 경험치 + 레벨업 동시 처리
    static func updateUserExpAndLevel(earnedExp: Int) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ 로그인 유저 없음")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        db.runTransaction({ transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(userRef)
                var currentExp = snapshot.get("exp") as? Int ?? 0
                var currentLevel = snapshot.get("level") as? Int ?? 1
                
                // 경험치 추가
                currentExp += earnedExp
                
                // 레벨업 처리 (여러 번 가능)
                while let need = levelUpTable[currentLevel], currentExp >= need {
                    currentExp -= need
                    currentLevel += 1
                }
                
                // Firestore 업데이트
                transaction.updateData([
                    "exp": currentExp,
                    "level": currentLevel,
                    "lastLogin": Timestamp(date: Date())
                ], forDocument: userRef)
                
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            return nil
        }) { _, error in
            if let error = error {
                print("❌ 트랜잭션 실패: \(error.localizedDescription)")
            } else {
                print("✅ EXP & 레벨 업데이트 성공")
            }
        }
    }
}
