//
//  SuccessReward.swift
//  Cobling
//
//  Created by 박종민 on 1/30/26.
//

import Foundation

struct SuccessReward {
    
    // 서버 기준 최종 결과
    let level: Int          // Firestore users.level
    let currentExp: CGFloat // Firestore users.exp
    let maxExp: CGFloat     // maxExpForLevel(level)

    // 이번 퀘스트 보상 (연출용)
    let gainedExp: Int      // base + bonus 합산 값

    // 연출 분기용
    let isPerfectClear: Bool
}
