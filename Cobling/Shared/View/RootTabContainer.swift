//
//  RootTabContainer.swift
//  Cobling
//
//  Created by 박종민 on 6/24/25.
//

import SwiftUI

// RootTabContainer: 하단 탭바와 현재 선택된 탭의 화면을 함께 구성하는 뷰
struct RootTabContainer: View {
    @EnvironmentObject var appState : AppState // 앱 전역 상태를 관리하는 AppState 객체를 환경 객체로 선언

    var body: some View {
        ZStack(alignment: .bottom) { // 하단 정렬된 ZStack으로 탭 콘텐츠 + 탭바 구성
            VStack(spacing: 0) { // 콘텐츠 영역 VStack (탭 전환 시 전환되는 화면들)
                switch appState.selectedTab { // 현재 선택된 탭에 따라 화면 전환
                case .quest: // 퀘스트 탭이 선택된 경우
                    NavigationStack { // 네비게이션 스택을 사용해 뷰 계층 전환 가능하도록
                        QuestListView() // 퀘스트 리스트 화면 표시
                    }
                case .journal: // 기록장 탭이 선택된 경우
                    JournalView() // 기록장 화면 표시
                    
                case .home: // 홈 탭이 선택된 경우
                    HomeView() // 홈 화면 표시
                    
                case .ranking: // 랭킹 탭이 선택된 경우
                    RankingView() // 랭킹 화면 표시
                    
                case .profile: // 프로필 탭이 설정된 경우
                    SettingsView() // 설정(프로필) 화면 표시
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 콘텐츠 영역이 화면 전체를 채우도록 설정
            .ignoresSafeArea(.keyboard) // 키보드 올라올 때 뷰 밀림 방지

            FloatingTabBar(selectedTab: $appState.selectedTab) // 하단 고정 탭바 뷰 추가
                            .padding(.bottom, 16) // 하단 여백 조절 (Safe Area 위로)
        }
        .edgesIgnoringSafeArea(.bottom) // 탭바가 하단까지 붙게
    }
}

#Preview {
    RootTabContainer()
        .environmentObject(AppState())
}
