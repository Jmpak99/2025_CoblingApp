//
//  AppRootView.swift
//  Cobling
//
//  Created by 박종민 on 6/24/25.
//

import SwiftUI

// 앱 전체의 루트 뷰를 정의하는 구조체
// 스플래시 화면이 끝나면 탭이 포함된 메인 화면으로 전환됨
struct AppRootView: View {
    @EnvironmentObject var appState: AppState // 앱의 전역 상태를 관리하는 AppState를 환경 객체로 주입받음

    var body: some View {
        Group { // 조건에 따라 서로 다른 뷰를 보여주기 위한 Group 컨테이너
            if appState.isSplashDone { // 스플래시가 끝났는지 여부
                RootTabContainer() // 탭바 포함된 화면
            } else {
                SplashView() // 스플래시 화면을 보여줌
                    .onAppear { // 뷰가 나타날 때 실행
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // 2초 후에
                            appState.isSplashDone = true // 스플래시 완료 상태로 변경하여 화면 전환 유도
                        }
                    }
            }
        }
    }
}
