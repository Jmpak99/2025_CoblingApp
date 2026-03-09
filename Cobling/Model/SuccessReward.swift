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
    
    // 챕터 보너스
    let chapterBonusExp: Int
    let isChapterCleared: Bool
    
    // "현재 완료 상태"가 아니라 "이번 클리어로 방금 달성했는지"로 변경
    let didJustCompleteDailyMission: Bool
    let didJustCompleteMonthlyMission: Bool
    
    // 필요하면 현재 완료 상태도 같이 보관 가능
    let isDailyMissionCompleted: Bool
    let isMonthlyMissionCompleted: Bool
}
