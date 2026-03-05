//
//  HomeView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var homeVM = HomeViewModel()

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel

    private var greetingText: String {
        if let nick = authVM.userProfile?.nickname, !nick.isEmpty {
            return "반가워요 \(nick)님"
        } else {
            return "반가워요"
        }
    }
    
    // MARK: - 캐릭터 에셋 이름 (DB stage 연동, stage 규칙 통일)
    private var homeCharacterAssetName: String {
        let stage = (authVM.userProfile?.character.stage ?? "egg")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let allowed: Set<String> = ["egg", "kid", "cobling", "legend"]
        let safeStage = allowed.contains(stage) ? stage : "egg"

        return "cobling_stage_\(safeStage)"
    }

    var body: some View {
        NavigationView {
            // 스크롤 가능하도록 ScrollView로 감싸기
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - 상단 제목
                    HStack {
                        Text("홈")
                            .font(.pretendardBold34)
                            .padding(.top, 16)
                            .padding(.leading, 24)
                        Spacer()
                    }

                    // MARK: - 인삿말
                    VStack(spacing: 4) {
                        Text(greetingText)
                            .font(.leeseoyun24)
                            .multilineTextAlignment(.center)
                        Text("저는 코블링이에요!")
                            .font(.leeseoyun24)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 48)

                    // MARK: - 캐릭터 이미지
                    Image(homeCharacterAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)

                    // MARK: - 키우러 가기 버튼
                    Button(action: {
                        appState.selectedTab = .quest
                    }) {
                        Text("키우러 가기")
                            .font(.pretendardRegular16)
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color(hex: "#E9E8DD"))
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)

                    // MARK: - 레벨 카드 (HomeViewModel 값 사용)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "#F8F8F6"))
                        .frame(width: 335, height: 72)
                        .overlay(
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Lv. \(homeVM.level)")
                                    .font(.gmarketMedium18)
                                    .foregroundColor(Color(hex: "#1D260D"))

                                HStack {
                                    let maxBarWidth: CGFloat = 230
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(hex: "#E9E8DD"))
                                            .frame(width: 230, height: 16)
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(hex: "#EA4C89"))
                                            .frame(width: maxBarWidth * homeVM.expPercent, height: 16)
                                    }
                                    Spacer()
                                    Text(String(format: "%.0f%%", homeVM.expPercent * 100))
                                        .font(.gmarketMedium16)
                                        .foregroundColor(Color(hex: "#1D260D"))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        )

                    // 미션 완료 상태
                    let dailyCompleted = homeVM.dailyIsCompleted
                    let monthlyCompleted = homeVM.monthlyIsCompleted

                    // DB에서 targetCount 가져오고, 초과하면 표시용 count는 target으로 고정
                    let dailyTarget = max(homeVM.dailyTargetCount, 1)
                    let monthlyTarget = max(homeVM.monthlyTargetCount, 1)

                    let displayDailyCount = min(homeVM.dailyCount, dailyTarget)
                    let displayMonthlyCount = min(homeVM.monthlyCount, monthlyTarget)

                    // MARK: - 오늘의 미션 카드 (DB title/subtitle/targetCount 연동)
                    if homeVM.dailyIsEnabled {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: dailyCompleted ? "#FFECEC" : "#F8F8F6"))
                            .frame(width: 335, height: 72)
                            .overlay(
                                HStack(alignment: .center) {
                                    Image(systemName: "questionmark.circle")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.gray)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(homeVM.dailyTitle) // DB 연동
                                            .font(.gmarketMedium16)
                                            .foregroundColor(.black)

                                        Text("\(homeVM.dailySubtitle) (\(displayDailyCount)/\(dailyTarget))") // DB 연동
                                            .font(.pretendardRegular14)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 4)

                                    Spacer()

                                    Image(systemName: dailyCompleted ? "checkmark.square.fill" : "square")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(dailyCompleted ? Color(hex: "#EA4C89") : .gray)
                                }
                                .padding(.horizontal, 20)
                            )
                    }

                    // MARK: - 월간 미션 카드 (DB title/subtitle/targetCount 연동)
                    if homeVM.monthlyIsEnabled {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: monthlyCompleted ? "#FFECEC" : "#F8F8F6"))
                            .frame(width: 335, height: 72)
                            .overlay(
                                HStack(alignment: .center) {
                                    Image(systemName: "questionmark.circle")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.gray)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(homeVM.monthlyTitle) // DB 연동
                                            .font(.gmarketMedium16)
                                            .foregroundColor(.black)

                                        Text("\(homeVM.monthlySubtitle) (\(displayMonthlyCount)/\(monthlyTarget))") // DB 연동
                                            .font(.pretendardRegular14)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 4)

                                    Spacer()

                                    Image(systemName: monthlyCompleted ? "checkmark.square.fill" : "square")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(monthlyCompleted ? Color(hex: "#EA4C89") : .gray)
                                }
                                .padding(.horizontal, 20)
                            )
                    }

                    // 스크롤에서 마지막 콘텐츠가 탭바/하단에 가리지 않도록 여백
                    Spacer().frame(height: 50)
                }
                // ScrollView 안에서 좌우 패딩 통일(원하시면 값 조정 가능)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            homeVM.startListeningUserData()
        }
        .onDisappear {
            homeVM.stopListeningUserData()
        }
    }
}



#Preview {
    // 프리뷰용 더미 VM 주입(닉네임/스테이지 보이게 하려면 아래처럼 세팅)
    let previewAuth = AuthViewModel()

    return HomeView()
        .environmentObject(AppState())
}
