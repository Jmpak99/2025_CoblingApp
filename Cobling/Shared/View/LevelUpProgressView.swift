import SwiftUI

struct LevelUpProgressView: View {

    // 최종(서버) 결과
    let finalLevel: Int
    let finalExp: CGFloat

    // 1단계/2단계 획득량
    let subQuestGain: CGFloat
    let chapterBonusGain: CGFloat

    // 2단계 여부
    let enableTwoStage: Bool

    // 외부(다이얼로그)의 레벨 텍스트를 같이 올리기 위한 바인딩
    @Binding var displayedLevel: Int
    
    // 현재 애니메이션 중 exp/maxExp를 바깥에서 표기하기 위한 바인딩
    @Binding var displayedExp: CGFloat
    @Binding var displayedMaxExp: CGFloat

    // 레벨별 maxExp 함수 (QuestViewModel과 동일 테이블 전달)
    let maxExpForLevel: (Int) -> CGFloat

    // 2단계 시작/전체 종료 콜백 (버튼 활성화 타이밍 제어용)
    var onSecondStageStart: () -> Void = {}
    var onAllStagesFinished: () -> Void = {}
    
    // 시작 상태 계산 결과를 바깥에 알려주는 콜백
    var onStartComputed: (_ startLevel: Int, _ startExp: CGFloat, _ startMaxExp: CGFloat) -> Void = { _,_,_  in }


    // ====== 내부 애니메이션 상태 ======
    @State private var animLevel: Int = 1
    @State private var animExp: CGFloat = 0
    @State private var animMaxExp: CGFloat = 100
    
    // 1단계 → 2단계 연출 템포 조절용 상수
    private let stage2TextDelay: TimeInterval = 0.65   // 1단계 끝나고 "챕터 보너스 텍스트" 보여주기까지 텀
    private let stage2GaugeDelay: TimeInterval = 0.85  // 1단계 끝나고 "챕터 보너스 게이지" 시작까지 텀 (텍스트보다 늦게)


    private var progressRatio: CGFloat {
        guard animMaxExp > 0 else { return 0 }
        return min(animExp / animMaxExp, 1.0)
    }

    private var percentText: Int {
        guard animMaxExp > 0 else { return 0 }
        return Int((animExp / animMaxExp) * 100)
    }

    var body: some View {
        ZStack(alignment: .center) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "E5E5E5"))
                    .frame(height: 14)

                Capsule()
                    .fill(Color(hex: "FFD475"))
                    .frame(width: max(12, progressRatio * 220))
                    .frame(height: 14)
            }
            .frame(width: 220)

            // 중앙 퍼센트(진행중 퍼센트)
            Text("\(percentText)%")
                .font(.pretendardBold12)
                .foregroundColor(.gray)
        }
        .onAppear {
            setupStartStateAndPlay()
        }
    }

    // MARK: - 시작 상태 계산 + 실행
    private func setupStartStateAndPlay() {
        let totalGain: CGFloat = enableTwoStage ? (subQuestGain + chapterBonusGain) : subQuestGain

        // “최종 상태”에서 역으로 totalGain을 빼서 시작 상태 계산
        let start = rewindFromFinal(finalLevel: finalLevel, finalExp: finalExp, subtract: totalGain)

        animLevel = start.level
        animExp = start.exp
        animMaxExp = maxExpForLevel(animLevel)

        displayedLevel = animLevel
        
        // 시작 상태를 바깥으로 전달 + 분수표기용 바인딩 초기화
        onStartComputed(animLevel, animExp, animMaxExp)
        displayedExp = animExp
        displayedMaxExp = animMaxExp


        // 1단계 시작
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animateGain(subQuestGain) {
                // 1단계 종료 후 2단계
                guard enableTwoStage, chapterBonusGain > 0 else {
                    onAllStagesFinished()
                    return
                }

                // 2단계 텍스트를 "조금 쉬었다가" 보여주기
                DispatchQueue.main.asyncAfter(deadline: .now() + stage2TextDelay) {
                    onSecondStageStart()
                }

                // 2단계 게이지는 텍스트보다 더 늦게 시작(원하는 '시간 차' 연출)
                DispatchQueue.main.asyncAfter(deadline: .now() + stage2GaugeDelay) {
                    animateGain(chapterBonusGain) {
                        onAllStagesFinished()
                    }
                }
            }
        }
    }


    // MARK: - 레벨 경계 넘기는 gain 애니메이션 (핵심)
    private func animateGain(_ amount: CGFloat, completion: @escaping () -> Void) {
        var remaining = max(0, amount)

        func step() {
            guard remaining > 0 else {
                completion()
                return
            }

            let space = max(0, animMaxExp - animExp)

            // 이번 스텝에서 이 레벨 안에서 끝나면
            if remaining < space {
                let target = animExp + remaining
                remaining = 0

                withAnimation(.easeOut(duration: 0.85)) {
                    animExp = target
                }
                
                // 바깥 분수표기 갱신
                displayedExp = target
                displayedMaxExp = animMaxExp
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                    completion()
                }
                return
            }

            // 레벨업을 해야 하면: 1) 100%까지 채우기
            remaining -= space

            withAnimation(.easeOut(duration: 0.65)) {
                animExp = animMaxExp
            }
            
            // 바깥 분수표기 갱신
            displayedExp = animMaxExp
            displayedMaxExp = animMaxExp

            // 2) 채운 뒤 살짝 텀 → 레벨업 처리(레벨+1, exp=0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65 + 0.12) {
                animLevel += 1
                displayedLevel = animLevel

                animExp = 0
                animMaxExp = maxExpForLevel(animLevel)
                
                // 레벨업 직후 바깥 분수표기 갱신
                displayedExp = 0
                displayedMaxExp = animMaxExp

                // 다음 레벨에서 남은 gain 계속
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    step()
                }
            }
        }

        step()
    }

    // MARK: - 최종 상태에서 subtract만큼 되돌려 시작 상태를 계산
    private func rewindFromFinal(finalLevel: Int, finalExp: CGFloat, subtract: CGFloat) -> (level: Int, exp: CGFloat) {
        var level = finalLevel
        var exp = finalExp
        var remain = max(0, subtract)

        // exp는 “현재 레벨 안에서의 exp”라고 가정 (users.exp가 그렇게 저장된 구조일 때)
        // 만약 users.exp가 누적exp라면 여기 로직이 달라져야 해요(말해주시면 바로 바꿔드릴게요).
        while remain > 0 {
            if exp >= remain {
                exp -= remain
                remain = 0
            } else {
                remain -= exp
                level = max(1, level - 1)
                exp = maxExpForLevel(level) // 이전 레벨 끝 지점으로 이동
                if level == 1 && remain > exp {
                    // 안전장치: 더 못 내려가면 0에서 멈춤
                    exp = 0
                    remain = 0
                }
            }
        }
        return (level, exp)
    }
}
