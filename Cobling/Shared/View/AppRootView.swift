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
///   - 로그인 X  → LoginView(‘가입하기’ 누르면 SignupView로 푸시)
struct AppRootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var tabBarViewModel: TabBarViewModel

    // 로그인 화면에서 ‘가입하기’ 탭 시 사인업으로 푸시
    @State private var goToSignup = false

    var body: some View {
        ZStack {
            if !appState.isSplashDone {
                SplashView()
            } else if authVM.isSignedIn {
                RootTabContainer()
            } else {
                // ✅ 로그인/회원가입 내비게이션 스택
                NavigationStack {
                    LoginView(
                        onBack: { /* 필요시 처리 */ },
                        onLoginSuccess: { /* 상태는 Auth 리스너로 자동 반영 */ },
                        onTapSignup: { goToSignup = true }
                    )
                    .navigationDestination(isPresented: $goToSignup) {
                        SignupView(
                            onTapLogin: { /* 상태는 Auth 리스너로 자동 반영 */ },
                            onTapEmailSignup: { /* 필요 시 트래킹 등 */ }
                        )
                    }
                }
            }
        }
        // 스플래시 타이머(공통 modifier)
        .task {
            guard !appState.isSplashDone else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초
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
