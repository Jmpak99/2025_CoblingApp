//
//  Untitled.swift
//  Cobling
//
//  Created by 박종민 on 1/30/26.
//

import SwiftUI

struct LevelUpProgressView: View {

    let level: Int
    let currentExp: CGFloat      // 서버 기준 최종 EXP
    let gainedExp: CGFloat       // 이번 퀘스트로 얻은 EXP (연출용)
    let maxExp: CGFloat          // 서버 기준 maxExp

    @State private var animatedExp: CGFloat = 0

    private var progressRatio: CGFloat {
        guard maxExp > 0 else { return 0 }
        return min(animatedExp / maxExp, 1.0)
    }

    var body: some View {
        ZStack(alignment: .leading) {

            Capsule()
                .fill(Color(hex: "E5E5E5"))
                .frame(height: 14)

            Capsule()
                .fill(Color(hex: "FFD475"))
                .frame(width: max(12, progressRatio * 220))
                .frame(height: 14)
                .animation(.easeOut(duration: 0.9), value: animatedExp)
        }
        .frame(width: 220)
        .onAppear {
            playAnimation()
        }
    }

    private func playAnimation() {
        // ⭐ 핵심: 서버 기준 값에서 "연출용 EXP"만 빼서 시작점 계산
        let startExp = max(currentExp - gainedExp, 0)

        animatedExp = startExp

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animatedExp = currentExp
        }
    }
}
