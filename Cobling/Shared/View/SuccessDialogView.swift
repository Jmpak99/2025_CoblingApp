//
//  SuccessDialogView.swift
//  Cobling
//
//  Created by 박종민 on 7/29/25.
//

import SwiftUI

struct SuccessDialogView: View {
    let reward : SuccessReward
    var onRetry: () -> Void
    var onNext: () -> Void
    
    private var expPercent: Int {
        guard reward.maxExp > 0 else { return 0 }
        return Int((reward.currentExp / reward.maxExp) * 100)
    }


    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 18) {

                // =========================
                // 🎉 헤드라인
                // =========================
                Text("🎉 성공!")
                    .font(.pretendardBold18)
                    .foregroundColor(.black)

                Text("코블링이 성장했어")
                    .font(.pretendardMedium14)
                    .foregroundColor(.black)

                // =========================
                // ⭐ 레벨 표시 (서버 기준)
                // =========================
                Text("Lv. \(reward.level)")
                    .font(.pretendardBold24)
                    .foregroundColor(.black)

                // =========================
                // 🔶 EXP Progress
                // =========================
                VStack(spacing: 6) {

                    ZStack {
                        LevelUpProgressView(
                            level: reward.level,
                            currentExp: reward.currentExp,
                            gainedExp: CGFloat(reward.gainedExp), // 애니메이션용
                            maxExp: reward.maxExp
                        )

                        // ⭐ 서버 기준 퍼센트
                        Text("\(expPercent)%")
                            .font(.pretendardBold12)
                            .foregroundColor(.gray)
                    }

                    Text("+\(reward.gainedExp) EXP")
                        .font(.pretendardMedium12)
                        .foregroundColor(.gray)
                }

                // =========================
                // 🏅 Perfect 보너스
                // =========================
                if reward.isPerfectClear {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FFB703"))

                        Text("완벽한 해결!")
                            .font(.pretendardMedium12)
                            .foregroundColor(Color(hex: "7A5A00"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FFF3CD"))
                    .cornerRadius(10)
                }

                // =========================
                // 버튼
                // =========================
                HStack(spacing: 14) {
                    Button(action: onRetry) {
                        Text("다시하기")
                            .font(.pretendardMedium16)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "EDEBE5"))
                            .cornerRadius(12)
                    }

                    Button(action: onNext) {
                        Text("다음 퀘스트로")
                            .font(.pretendardMedium16)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "FFD475"))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(22)
            .padding(.horizontal, 36)
        }
    }
}

struct SuccessDialogView_Previews: PreviewProvider {
    static var previews: some View {
        Group {

            // ❌ 레벨업 안 됨
            ZStack {
                Color.gray.opacity(0.2).ignoresSafeArea()

                SuccessDialogView(
                    reward: SuccessReward(
                        level: 3,
                        currentExp: 180,
                        maxExp: 250,
                        gainedExp: 9,          // ⭐ base + bonus 합산
                        isPerfectClear: true
                    ),
                    onRetry: {},
                    onNext: {}
                )
            }
            .previewDisplayName("EXP Only")

            // ✅ 레벨업 됨
            ZStack {
                Color.gray.opacity(0.2).ignoresSafeArea()

                SuccessDialogView(
                    reward: SuccessReward(
                        level: 4,              // ⭐ 이미 레벨업된 상태
                        currentExp: 10,         // ⭐ 남은 EXP
                        maxExp: 250,
                        gainedExp: 15,
                        isPerfectClear: false
                    ),
                    onRetry: {},
                    onNext: {}
                )
            }
            .previewDisplayName("LEVEL UP")
        }
    }
}
