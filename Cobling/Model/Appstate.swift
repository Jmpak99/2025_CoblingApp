//
//  Appstate.swift
//  Cobling
//
//  Created by 박종민 on 6/24/25.
//


import Foundation

// 앱 전역 상태를 관리하는 ObservableObject 클래스
class AppState: ObservableObject {
    @Published var isSplashDone = false // 스플래시 화면이 끝났는지 여부를 나타내는 상태 변수
    @Published var selectedTab: TabItem = .home // 현재 선택된 탭을 나타내는 상태 변수, 기본값은 홈
}
