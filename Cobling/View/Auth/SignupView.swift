//
//  SignupView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

struct SignupView: View {
    // 기존 콜백
    var onTapLogin: () -> Void
    var onTapEmailSignup: () -> Void

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pushToLogin = false
    @State private var pushToEmailSignup = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF2DC").ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer().frame(height: 60)

                // 상단 로고/타이틀 영역 (스크린샷 느낌)
                VStack(spacing: 18) {
                    // 예시: 기존 "cobling_character_super" 그대로 사용
                    Image("cobling_character_super")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 180)

                    Text("코블링")
                        .font(.leeseoyun48)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 6) { Text("코블링과 함께하는 코딩 모험")
                        Text("지금 시작해요 !")
                    }
                    .font(.gmarketMedium16) .foregroundColor(.black.opacity(0.65))
                }

                Spacer().frame(height: 200)

                // 로그인 버튼
                VStack(spacing: 10) {

//                    // 1️⃣ Apple
//                    SocialLoginButton(
//                        style: .apple,
//                        title: "Apple로 로그인",
//                        leftIcon: .system(name: "applelogo")
//                    ) {
//                        Task { await authVM.handleAppleLogin() }
//                    }

//                    // 2️⃣ Google
//                    SocialLoginButton(
//                        style: .google,
//                        title: "Google로 로그인",
//                        leftIcon: .asset(name: "ic_google")
//                    ) {
//                        Task { await authVM.handleGoogleLogin() }
//                    }

//                    // 3️⃣ Kakao
//                    SocialLoginButton(
//                        style: .kakao,
//                        title: "카카오로 시작하기",
//                        leftIcon: .asset(name: "ic_kakao")
//                    ) {
//                        Task { await authVM.handleKakaoLogin() }
//                    }

                    // 4️⃣ 이메일로 시작하기 (화이트 스타일)
                    SocialLoginButton(
                        style: .email,
                        title: "이메일로 시작하기",
                        leftIcon: .system(name: "envelope")
                    ) {
                        onTapLogin()
                        pushToLogin = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)

                Spacer(minLength: 0)
            }
        }
        
        // 카피라이트를 화면 최하단에 고정
        .safeAreaInset(edge: .bottom) {
            Text("Copyright 2026. cobling")
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.25))
                .padding(.bottom, 10) // 바닥에서 살짝 띄우기
        }
        
        .navigationBarBackButtonHidden(true)
        // 뒤로가기 코드 제거
//        .toolbar {
//            ToolbarItem(placement: .topBarLeading) {
//                Button {
//                    dismiss()
//                } label: {
//                    Image(systemName: "chevron.left")
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(.black.opacity(0.75))
//                }
//            }
//        }
        // 기존 네비게이션들(필요하면 유지)
        .navigationDestination(isPresented: $pushToLogin) {
            LoginView(
                onBack: { /* 기본 백 버튼 사용 */ },
                onLoginSuccess: { onTapLogin() },
                onTapSignup: {
                    pushToLogin = false
                    pushToEmailSignup = true
                }
            )
            .environmentObject(authVM)
        }
        .navigationDestination(isPresented: $pushToEmailSignup) {
            EmailSignupView(onSignupSuccess: {
                pushToEmailSignup = false
                pushToLogin = true
            })
            .environmentObject(authVM)
        }
        // SNS 로그인 성공하면 상위로 넘기고 싶으면 이거 추가 추천
        .onChange(of: authVM.isSignedIn) { _, newValue in
            if newValue { onTapLogin() }
        }
    }
}

// MARK: - Social Button

private struct SocialLoginButton: View {

    private let iconSize: CGFloat = 25   // 여기서 아이콘 크기 통일 관리

    enum Style {
        case apple, google, kakao, email

        var background: Color {
            switch self {
            case .apple: return .black
            case .google: return .white
            case .kakao: return Color(hex: "#FEE500")
            case .email: return .white
            }
        }

        var foreground: Color {
            switch self {
            case .apple: return .white
            case .google: return .black
            case .kakao: return .black
            case .email: return .black
            }
        }

        var border: (Color, CGFloat) {
            switch self {
            case .google:
                return (.black.opacity(0.12), 1)
            case .email:
                return (.black.opacity(0.10), 1)
            default:
                return (.clear, 0)
            }
        }
    }

    enum LeftIcon {
        case system(name: String)
        case asset(name: String)
    }

    let style: Style
    let title: String
    let leftIcon: LeftIcon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {

                // 🔥 아이콘 영역 완전 통일
                Group {
                    switch leftIcon {
                    case .system(let name):
                        Image(systemName: name)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(style.foreground)

                    case .asset(let name):
                        Image(name)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: iconSize, height: iconSize) // 🔥 여기서 완전 동일 크기
                .padding(.leading, 18)

                Spacer()

                Text(title)
                    .font(.gmarketBold16)
                    .foregroundColor(style.foreground)

                Spacer()

                Color.clear
                    .frame(width: iconSize, height: iconSize)
                    .padding(.trailing, 18)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(style.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(style.border.0, lineWidth: style.border.1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}
//  커스텀 버튼 눌림 효과(심사/UX에 도움)
private struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        SignupView(onTapLogin: {}, onTapEmailSignup: {})
            .environmentObject(AuthViewModel())
    }
}
