//
//  SuccessDialogView.swift
//  Cobling
//
//  Created by 박종민 on 7/29/25.
//

import SwiftUI

struct SuccessDialogView: View {
    let reward: SuccessReward
    var onRetry: () -> Void
    var onNext: () -> Void


    // 게이지 애니메이션과 함께 레벨 텍스트도 같이 변하도록 상태로 분리
    @State private var displayedLevel: Int = 1

    // 2단계(서브퀘스트 → 챕터보너스) 텍스트 연출용 상태
    @State private var showChapterBonusStage: Bool = false

    // 2단계 게이지 연출 중이면 Next 비활성화
    @State private var isAnimatingTwoStage: Bool = false

    // 2단계 연출 여부 판단
    private var shouldShowChapterBonusLine: Bool {
        reward.isChapterCleared && reward.chapterBonusExp > 0
    }
    


    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 18) {

                Text("🎉 성공!")
                    .font(.pretendardBold24)
                    .foregroundColor(.black)

                Text("코블링이 한 단게 진화했어!")
                    .font(.pretendardMedium14)
                    .foregroundColor(.black)

                Text("Lv. \(displayedLevel)")
                    .font(.pretendardBold24)
                    .foregroundColor(.black)

                VStack(spacing: 6) {

                    LevelUpProgressView(
                        finalLevel: reward.level,
                        finalExp: reward.currentExp,
                        subQuestGain: CGFloat(reward.gainedExp),
                        chapterBonusGain: CGFloat(reward.chapterBonusExp),
                        enableTwoStage: shouldShowChapterBonusLine,
                        displayedLevel: $displayedLevel,
                        maxExpForLevel: { level in
                            let table: [Int: CGFloat] = [
                                1: 100, 2: 120, 3: 160, 4: 200, 5: 240,
                                6: 310, 7: 380, 8: 480, 9: 600, 10: 750,
                                11: 930, 12: 1160, 13: 1460, 14: 1820, 15: 2270,
                                16: 2840, 17: 3550, 18: 4440, 19: 5550
                            ]
                            return table[level] ?? 100
                        },
                        onSecondStageStart: {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                showChapterBonusStage = true
                            }
                        },
                        onAllStagesFinished: {
                            isAnimatingTwoStage = false
                        }
                    )

                    // ⭐ 수정: EXP 텍스트는 2줄 유지
                    VStack(spacing: 4) {
                        Text("+\(reward.gainedExp) EXP")
                            .font(.pretendardMedium12)
                            .foregroundColor(.gray)

                        if shouldShowChapterBonusLine {
                            Text(showChapterBonusStage ? "+\(reward.chapterBonusExp) EXP (챕터 보너스)" : " ")
                                .font(.pretendardMedium12)
                                .foregroundColor(Color(hex: "7A5A00"))
                        }
                    }
                }

                // ⭐ 수정: 챕터 클리어를 완벽보다 위로 이동 (우선순위 강조)
                if shouldShowChapterBonusLine {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13)) //
                            .foregroundColor(Color(hex: "FFD475"))

                        Text("챕터 클리어!")
                            .font(.pretendardMedium14) //
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "FFF2CC"))
                    .cornerRadius(12)
                }

                // 완벽은 보조 칩 느낌 유지
                if reward.isPerfectClear {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "FFB703"))

                        Text("완벽한 해결")
                            .font(.pretendardMedium12)
                            .foregroundColor(Color(hex: "7A5A00"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "FFF3CD"))
                    .cornerRadius(10)
                }

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
                        Text(isAnimatingTwoStage ? "정산 중..." : "다음 퀘스트로")
                            .font(.pretendardMedium16)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: "FFD475"))
                            .cornerRadius(12)
                            .opacity(isAnimatingTwoStage ? 0.55 : 1.0)
                    }
                    .disabled(isAnimatingTwoStage)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(22)
            .padding(.horizontal, 36)
        }
        .onAppear {
            displayedLevel = reward.level
            isAnimatingTwoStage = shouldShowChapterBonusLine
            showChapterBonusStage = false

            print(
                "🟡 SuccessDialog reward 확인",
                "isChapterCleared:", reward.isChapterCleared,
                "chapterBonusExp:", reward.chapterBonusExp,
                "gainedExp:", reward.gainedExp,
                "level:", reward.level,
                "exp:", reward.currentExp,
                "maxExp:", reward.maxExp
            )

            print(
                "🟡 shouldShowChapterBonusLine:",
                shouldShowChapterBonusLine
            )
        }
    }
}

#if DEBUG
struct SuccessDialogView_Previews: PreviewProvider {
    static var previews: some View {
        Group {

            // 🟢 1️⃣ 일반 클리어 (챕터 보너스 없음)
            SuccessDialogView(
                reward: SuccessReward(
                    level: 2,
                    currentExp: 35,
                    maxExp: 120,
                    gainedExp: 9,
                    isPerfectClear: false,
                    chapterBonusExp: 0,
                    isChapterCleared: false
                ),
                onRetry: {},
                onNext: {}
            )
            .previewDisplayName("기본 클리어")

            // 🟡 2️⃣ 챕터 보너스 포함 (2단계 연출)
            SuccessDialogView(
                reward: SuccessReward(
                    level: 2,
                    currentExp: 20,
                    maxExp: 120,
                    gainedExp: 9,
                    isPerfectClear: false,
                    chapterBonusExp: 30,
                    isChapterCleared: true
                ),
                onRetry: {},
                onNext: {}
            )
            .previewDisplayName("챕터 보너스 포함")

            // 🏆 3️⃣ 완벽 클리어 + 챕터 보너스
            SuccessDialogView(
                reward: SuccessReward(
                    level: 3,
                    currentExp: 10,
                    maxExp: 160,
                    gainedExp: 11,
                    isPerfectClear: true,
                    chapterBonusExp: 30,
                    isChapterCleared: true
                ),
                onRetry: {},
                onNext: {}
            )
            .previewDisplayName("완벽 + 챕터 보너스")
        }
        .background(Color.gray.opacity(0.2))
        .previewLayout(.sizeThatFits)
    }
}
#endif
