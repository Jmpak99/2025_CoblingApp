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
        Color(hex: "#FFEEEF"), // 핑크
        Color(hex: "#FFF1DB"), // 베이지
        Color(hex: "#E3EDFB"), // 블루
        Color(hex: "#E8F6F3"), // 민트
        Color(hex: "#F3E8FF"), // 퍼플
        Color(hex: "#FFF4E6"), // 오렌지
    ]

    // MARK: - 챕터 기준 색상
    /// 챕터 카드 + 서브퀘스트 카드 공통 색상
    static func backgroundColor(order: Int) -> Color {
        guard !palette.isEmpty else { return .white }
        let index = max(order - 1, 0) % palette.count
        return palette[index]
    }
}
