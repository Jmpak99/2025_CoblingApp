//
//  AppRootView.swift
//  Cobling
//
//  Created by 박종민 on 6/24/25.
//

import SwiftUI

/// 앱 루트 컨테이너
/// - 스플래시 종료 후 인증 상태에 따라 분기:
///   - 로그인 O  → RootTabContainer()
///   - 로그인 X  → SignupView()
/// - SignupView의 콜백을 AppRoot에서 처리 (이메일 가입 시트/로그인 성공 전환)
struct AppRootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var tabBarViewModel: TabBarViewModel

    var body: some View {
        ZStack {
            if !appState.isSplashDone {
                SplashView()
            } else if authVM.isSignedIn {
                RootTabContainer()
            } else {
                // ✅ 푸시 내비게이션 사용
                NavigationStack {
                    SignupView(
                        onTapLogin: { authVM.isSignedIn = true },
                        onTapEmailSignup: { /* 필요 시 트래킹만 */ }
                    )
                }
            }
        }
        .task {
            guard !appState.isSplashDone else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            appState.isSplashDone = true
        }
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
        .environmentObject(TabBarViewModel())
}
