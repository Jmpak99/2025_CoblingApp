//
//  QuestTheme.swift
//  Cobling
//
//  Created by 박종민 on 1/21/26.
//

import SwiftUI

enum QuestTheme {

    // MARK: - 챕터 컬러 팔레트
    // 👉 챕터 수가 늘어나면 자동 순환
    private static let palette: [Color] = [
        Color(hex: "#FFEEEF"), // 1챕터 핑크  // 기본 이동
        Color(hex: "#F3E8FF"), // 2챕터 퍼플. // 공격
        Color(hex: "#E3EDFB"), // 3챕터 블루. // repeatCount
        Color(hex: "#DFF6E8"), // 4챕터 초록. // if
        Color(hex: "#FFF1DB"), // 5챕터 베이지 // 공격 + repeatCount
        Color(hex: "#FFF4E6"), // 6챕터 오렌지 // 공격 + 계속 반복
    ]

    // MARK: - 챕터 기준 색상
    /// 챕터 카드 + 서브퀘스트 카드 공통 색상
    static func backgroundColor(order: Int) -> Color {
        guard !palette.isEmpty else { return .white }
        let index = max(order - 1, 0) % palette.count
        return palette[index]
    }
}
