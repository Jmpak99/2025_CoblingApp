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
                // ✅ 푸시 내비게이션 시작점
                NavigationStack {
                    LoginView(
                        onBack: { /* 필요 시 커스텀 동작 */ },
                        onLoginSuccess: { authVM.isSignedIn = true },
                        onTapSignup: { goToSignup = true }   // ← 가입하기 탭 시 사인업으로 이동
                    )
                    // ✅ 목적지: 사인업 뷰 (푸시 전환)
                    .navigationDestination(isPresented: $goToSignup) {
                        SignupView(
                            onTapLogin: { authVM.isSignedIn = true },  // 사인업 내 로그인 성공 처리 시
                            onTapEmailSignup: { /* 이메일 가입 폼 진입 시 트래킹 등 */ }
                        )
                        .environmentObject(authVM) // (안전하게 명시 주입)
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
