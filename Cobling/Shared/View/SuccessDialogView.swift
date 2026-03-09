//
//  SuccessDialogView.swift
//  Cobling
//
//  Created by 박종민 on 7/29/25.
//

import SwiftUI

struct SuccessDialogView: View {
    let reward: SuccessReward
    let characterStage: String
    var onRetry: () -> Void
    var onNext: () -> Void
    
    // QuestViewModel 접근 (아웃트로 트리거용)
    @EnvironmentObject var viewModel: QuestViewModel

    // 아웃트로 중복 호출 방지 플래그
    @State private var didTriggerOutro: Bool = false

    // 게이지 애니메이션과 함께 레벨 텍스트도 같이 변하도록 상태로 분리
    @State private var displayedLevel: Int = 1
    
    // 시작 레벨(레벨업 여부 판단용)
    @State private var startLevel: Int = 1

    // 레벨업일 때만 분수표시(현재/최대)
    @State private var displayedExp: CGFloat = 0
    @State private var displayedMaxExp: CGFloat = 100

    // 기존 chapterBonus 전용 텍스트 연출 상태를
    // "추가 보상(챕터/일일/월간)" 전체 연출 상태로 사용
    @State private var showExtraRewardStage: Bool = false

    // 2단계 게이지 연출 중이면 Next 비활성화
    @State private var isAnimatingTwoStage: Bool = false

    // 일일 미션 보상 EXP
    private var dailyMissionGain: Int {
        reward.dailyMissionRewardExp
    }

    // 월간 미션 보상 EXP
    private var monthlyMissionGain: Int {
        reward.monthlyMissionRewardExp
    }

    // 2단계로 묶어서 보여줄 "추가 보상" 총합
    // - 챕터 보너스
    // - 일일 미션 보상
    // - 월간 미션 보상
    private var totalExtraRewardGain: Int {
        reward.chapterBonusExp + dailyMissionGain + monthlyMissionGain
    }

    // 기존 챕터 보너스 라인 여부가 아니라
    // "추가 보상 총합"이 있는지로 판별
    private var shouldShowExtraRewardLine: Bool {
        totalExtraRewardGain > 0
    }
    
    // 레벨업 여부
    private var didLevelUp: Bool {
        reward.level > startLevel
    }
    
    // "Next를 누르면 컷신(아웃트로)이 뜨는 상황" 판단용
    // - 챕터 클리어면 Next 버튼을 눌렀을 때 아웃트로 컷신을 띄우는 UX
    // - (보너스 exp가 0이어도) 챕터 클리어면 아웃트로를 띄우고 싶어서 분리
    private var shouldShowOutroOnNext: Bool {
        reward.isChapterCleared
    }
    
    // Next 버튼 텍스트 UX
    // - 챕터 클리어(=아웃트로 컷신이 뜸)일 때는 "다음(아웃트로)"
    // - 그 외는 기존 "다음 퀘스트로"
    private var nextButtonTitle: String {
        if isAnimatingTwoStage { return "정산 중..." }
        return shouldShowOutroOnNext ? "다음(아웃트로)" : "다음 퀘스트로"
    }
    
    // stage > 에셋 이름 매핑
    private var characterAssetName: String {
        let stage = characterStage.trimmingCharacters(in: .whitespacesAndNewlines)
        return stage.isEmpty ? "cobling_stage_egg" : "cobling_stage_\(stage)"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 18) {

                // 레벨업이면 타이틀 변경
                Text(didLevelUp ? "🎉 레벨업!" : "🎉 성공!")
                    .font(.pretendardBold24)
                    .foregroundColor(.black)

                Text(didLevelUp ? "코블링이 한 단계 진화했어!" : "코블링이 한 단계 성장했어!")
                    .font(.pretendardMedium14)
                    .foregroundColor(.black)
                
                // 캐릭터 추가 (가운데 정렬)
                Image(characterAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 2)
                    .accessibilityLabel("코블링 캐릭터")

                // 레벨업이면 "Lv.1 → Lv.2" 형태
                if didLevelUp {
                    Text("Lv.\(startLevel) → Lv.\(max(startLevel, displayedLevel))")
                        .font(.pretendardBold24)
                        .foregroundColor(.black)
                } else {
                    Text("Lv. \(displayedLevel)")
                        .font(.pretendardBold24)
                        .foregroundColor(.black)
                }

                VStack(spacing: 6) {

                    LevelUpProgressView(
                        finalLevel: reward.level,
                        finalExp: reward.currentExp,
                        subQuestGain: CGFloat(reward.gainedExp),

                        // 기존: chapterBonusExp만 2단계 gain으로 전달
                        // 변경: 챕터 보너스 + 일일 미션 보상 + 월간 미션 보상 전체를 2단계 gain으로 전달
                        chapterBonusGain: CGFloat(totalExtraRewardGain),

                        // 기존: reward.isChapterCleared && reward.chapterBonusExp > 0
                        // 변경: 추가 보상이 하나라도 있으면 2단계 연출
                        enableTwoStage: shouldShowExtraRewardLine,
                        displayedLevel: $displayedLevel,

                        // 분수표기용 바인딩 전달
                        displayedExp: $displayedExp,
                        displayedMaxExp: $displayedMaxExp,

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
                                // chapter bonus 전용 상태명이 아니라 extra reward 단계 표시
                                showExtraRewardStage = true
                            }
                        },
                        onAllStagesFinished: {
                            isAnimatingTwoStage = false

                            // 여기서는 아웃트로를 "자동 트리거" 하지 않습니다.
                            // - 사용자가 원한 플로우:
                            //   성공다이얼로그 → 게이지 끝 → "다음" 버튼 클릭 → 컷신(아웃트로)
                            // - 그래서 아웃트로 트리거는 QuestBlockView의 onNext에서 처리합니다.
                            // - (didTriggerOutro도 여기서는 사용하지 않아도 됩니다. 필요하면 완전히 제거 가능)
                        },

                        // 시작 상태를 받아 startLevel 세팅
                        onStartComputed: { sLevel, sExp, sMax in
                            startLevel = sLevel
                            displayedExp = sExp
                            displayedMaxExp = sMax
                        }
                    )
                    
                    // 레벨업일 때만 (현재/최대) 표시
                    if didLevelUp {
                        Text("\(Int(displayedExp)) / \(Int(displayedMaxExp)) EXP")
                            .font(.pretendardMedium12)
                            .foregroundColor(.gray)
                    }

                    // EXP 텍스트 영역
                    VStack(spacing: 4) {
                        Text("+\(reward.gainedExp) EXP")
                            .font(.pretendardMedium12)
                            .foregroundColor(.gray)

                        // 기존: 챕터 보너스만 따로 표시
                        // 변경: 추가 보상 전체(챕터/일일/월간) 표시
                        if shouldShowExtraRewardLine {
                            Text(showExtraRewardStage ? "+\(totalExtraRewardGain) EXP (추가 보상)" : " ")
                                .font(.pretendardMedium12)
                                .foregroundColor(Color(hex: "7A5A00"))
                        }

                        // 세부 보상 항목 표시
                        if showExtraRewardStage && reward.chapterBonusExp > 0 {
                            Text("챕터 보너스 +\(reward.chapterBonusExp) EXP")
                                .font(.pretendardMedium12)
                                .foregroundColor(Color(hex: "7A5A00"))
                        }

                        // 세부 보상 항목 표시
                        if showExtraRewardStage && dailyMissionGain > 0 {
                            Text("일일 미션 +\(dailyMissionGain) EXP")
                                .font(.pretendardMedium12)
                                .foregroundColor(Color(hex: "1B5E20"))
                        }

                        // 세부 보상 항목 표시
                        if showExtraRewardStage && monthlyMissionGain > 0 {
                            Text("월간 미션 +\(monthlyMissionGain) EXP")
                                .font(.pretendardMedium12)
                                .foregroundColor(Color(hex: "4A148C"))
                        }
                    }
                }

                // 챕터 클리어를 완벽보다 위로 이동 (우선순위 강조)
                if reward.isChapterCleared {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "FFD475"))

                        Text("챕터 클리어!")
                            .font(.pretendardMedium14)
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
                
                // 미션 배지 영역
                VStack(spacing: 8) {
                    if reward.didJustCompleteDailyMission {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "2E7D32"))

                            Text("일일 미션 달성!")
                                .font(.pretendardMedium12)
                                .foregroundColor(Color(hex: "1B5E20"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "E8F5E9"))
                        .cornerRadius(10)
                    }

                    if reward.didJustCompleteMonthlyMission {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "6A1B9A"))

                            Text("월간 미션 달성!")
                                .font(.pretendardMedium12)
                                .foregroundColor(Color(hex: "4A148C"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "F3E5F5"))
                        .cornerRadius(10)
                    }
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
                        // Next 버튼 텍스트 UX 적용
                        // - 정산 중: "정산 중..."
                        // - 챕터 클리어(=아웃트로 컷신 뜸): "다음(아웃트로)"
                        // - 일반: "다음 퀘스트로"
                        Text(nextButtonTitle)
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

            // 기존: 챕터 보너스 여부 기준
            // 변경: 추가 보상 총합 기준
            isAnimatingTwoStage = shouldShowExtraRewardLine

            // 기존: showChapterBonusStage
            // 변경: showExtraRewardStage
            showExtraRewardStage = false
            
            // 새로 뜰 때마다 중복 방지 플래그 초기화
            didTriggerOutro = false

            print(
                "🟡 SuccessDialog reward 확인",
                "isChapterCleared:", reward.isChapterCleared,
                "chapterBonusExp:", reward.chapterBonusExp,
                "dailyMissionRewardExp:", reward.dailyMissionRewardExp,
                "monthlyMissionRewardExp:", reward.monthlyMissionRewardExp,
                "gainedExp:", reward.gainedExp,
                "level:", reward.level,
                "exp:", reward.currentExp,
                "maxExp:", reward.maxExp
            )

            print(
                "🟡 shouldShowExtraRewardLine:",
                shouldShowExtraRewardLine
            )
            print("🟡 characterStage:", characterStage, "asset:", characterAssetName)
        }
    }
}

#if DEBUG
struct SuccessDialogView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessDialogView(
            reward: SuccessReward(
                level: 3,
                currentExp: 10,
                maxExp: 160,
                gainedExp: 11,
                isPerfectClear: true,
                chapterBonusExp: 140,
                isChapterCleared: true,
                didJustCompleteDailyMission: true,
                didJustCompleteMonthlyMission: true,
                isDailyMissionCompleted: true,
                isMonthlyMissionCompleted: true,
                dailyMissionRewardExp: 120,
                monthlyMissionRewardExp: 400   
            ),
            characterStage: "legend",
            onRetry: {},
            onNext: {}
        )
        .background(Color.gray.opacity(0.2))
        .previewLayout(.sizeThatFits)
    }
}
#endif
