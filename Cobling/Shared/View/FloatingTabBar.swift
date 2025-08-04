//
//  FloatingTabBar.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

// MARK: - TabItem Enum

enum TabItem: Int, CaseIterable {
    case quest, journal, home, ranking, profile // 5개의 탭 정의

    // 탭에 사용될 아이콘 이름 (Assets에 등록된 이미지 이름과 연결됨)
    var iconName: String {
        switch self {
        case .quest: return "tab_icon_quest"
        case .journal: return "tab_icon_journal"     // ⛔ 기록장 (탭바에 비표시)
        case .home: return "tab_icon_home"
        case .ranking: return "tab_icon_ranking"     // ⛔ 랭킹 (탭바에 비표시)
        case .profile: return "tab_icon_profile"
        }
    }

    // 탭에 표시될 텍스트 라벨
    var title: String {
        switch self {
        case .quest: return "퀘스트"
        case .journal: return "기록장"               // ⛔ 기록장 (탭바에 비표시)
        case .home: return "홈"
        case .ranking: return "랭킹"                 // ⛔ 랭킹 (탭바에 비표시)
        case .profile: return "프로필"
        }
    }
}

// MARK: - FloatingTabBar View (하단 탭바 UI 구성)

struct FloatingTabBar: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject var tabBarViewModel: TabBarViewModel

    // ⏳ 현재 탭바에 표시할 탭들만 정의
    private let visibleTabs: [TabItem] = [.quest, .home, .profile]

    var body: some View {
        if tabBarViewModel.isTabBarVisible {
            HStack(spacing: 0) {
                ForEach(visibleTabs, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 6) {
                            Image(tab.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)

                            Text(tab.title)
                                .font(.pretendardRegular12)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ? Color(hex: "FFF7E9") : Color.white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Color.white
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Preview Helper

struct StatefulPreviewWrapper<Value: Equatable, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}

// MARK: - Preview

struct FloatingTabBar_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(TabItem.home) { selectedTab in
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: selectedTab)
            }
            .environmentObject(TabBarViewModel())
            .background(Color.gray.opacity(0.1))
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}
