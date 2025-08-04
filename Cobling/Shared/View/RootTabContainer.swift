//
//  RootTabContainer.swift
//  Cobling
//
//  Created by 박종민 on 6/24/25.
//

import SwiftUI

// RootTabContainer: 하단 탭바와 현재 선택된 탭의 화면을 함께 구성하는 뷰
struct RootTabContainer: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var tabBarViewModel: TabBarViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                switch appState.selectedTab {
                case .quest:
                    NavigationStack {
                        QuestListView()
                    }
                case .home:
                    HomeView()
                case .profile:
                    NavigationStack {
                        SettingsView()
                    }
                    
                    
                case .journal, .ranking:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)

            if tabBarViewModel.isTabBarVisible { // ✅ 조건부로 탭바 표시
                FloatingTabBar(selectedTab: $appState.selectedTab)
                    .padding(.bottom, 16)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
#Preview {
    RootTabContainer()
        .environmentObject(AppState())
        .environmentObject(TabBarViewModel())
}
