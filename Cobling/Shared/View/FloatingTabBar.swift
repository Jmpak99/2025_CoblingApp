//
//  FloatingTabBar.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

// MARK: - TabItem Enum

enum TabItem: Int, CaseIterable { // Int와 CaseIterable 프로토콜 채택
    case quest, journal, home, ranking, profile // 5개의 탭 정의

    // 탭에 사용될 아이콘 이름 (Assets에 등록된 이미지 이름과 연결됨)
    var iconName: String {
        switch self {
        case .quest: return "tab_icon_quest"
        case .journal: return "tab_icon_journal"
        case .home: return "tab_icon_home"
        case .ranking: return "tab_icon_ranking"
        case .profile: return "tab_icon_profile"
        }
    }

    // 탭에 표시될 텍스트 라벨
    var title: String {
        switch self {
        case .quest: return "퀘스트"
        case .journal: return "기록장"
        case .home: return "홈"
        case .ranking: return "랭킹"
        case .profile: return "프로필"
        }
    }
}

// MARK: - FloatingTabBar View (하단 탭바 UI 구성)

struct FloatingTabBar: View {
    @Binding var selectedTab: TabItem // 선택된 탭을 바인딩으로 전달받음

    var body: some View {
        HStack(spacing: 0) { // 수평 정렬, 탭 사이 간격 없음
            ForEach(TabItem.allCases, id: \.self) { tab in // 모든 탭에 대해 반복
                Button(action: {
                    selectedTab = tab // 버튼 클릭 시 해당 탭을 선택
                }) {
                    VStack(spacing: 6) {  // 아이콘과 텍스트 수직 정렬
                        Image(tab.iconName) // 탭 아이콘 이미지
                            .resizable() // 크기 조절 가능하도록
                            .scaledToFit() // 비율 유지하며 맞춤
                            .frame(width: 28, height: 28) // 아이콘 크기 지정

                        Text(tab.title) // 탭 이름 텍스트
                            .font(.pretendardRegular12) // 폰트
                            .foregroundColor(.black) // 글자색 검정
                    }
                    .frame(maxWidth: .infinity) // 버튼의 가로 크기 균등하게
                    .padding(.vertical, 12) // 상하 패딩
                    .background(
                        selectedTab == tab ? Color(hex: "FFF7E9") :  Color.white // 선택된 탭이면 배경색 강조
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16)) // 둥근 배경 처리
                }
            }
        }
        .padding(.horizontal, 16) // 탭바 양옆 여백
        .padding(.vertical, 10) // 탭바 위아래 여백
        .background( // 전체 탭바 배경
            Color.white
                .clipShape(RoundedRectangle(cornerRadius: 32)) // 모서리 둥글게
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2) // 가벼운 그림자
        )
        .padding(.horizontal, 16) // 바깥쪽 여백
    }
}

// MARK: - Preview Helper

struct StatefulPreviewWrapper<Value: Equatable, Content: View>: View {
    @State private var value: Value // 프리뷰에서 사용할 상태 변수
    let content: (Binding<Value>) -> Content // 바인딩을 뷰에 전달하는 클로저
    
    // 초기값을 받아 상태 변수로 설정하고, 클로저로 뷰 구성
    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value) // 바인딩된 값을 클로저에 전달
    }
}

// MARK: - Preview

struct FloatingTabBar_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(TabItem.home) { selectedTab in // 초기 선택 탭: 홈
            VStack {
                Spacer() // 상단 공간 확보
                FloatingTabBar(selectedTab: selectedTab) // 플로팅 탭바 표시
            }
            .background(Color.gray.opacity(0.1)) // 배경색 설정
            .edgesIgnoringSafeArea(.bottom) // 탭바가 화면 하단까지 표시되도록 설정

        }
    }
}
