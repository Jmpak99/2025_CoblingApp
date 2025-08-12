//
//  SignupView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//


import SwiftUI

struct SignupView: View {
    var onTapLogin: () -> Void
    var onTapEmailSignup: () -> Void

    @EnvironmentObject var authVM: AuthViewModel
    @State private var pushToLogin = false
    @State private var pushToEmailSignup = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF2DC").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                VStack(spacing: 20) {
                    Image("cobling_character_super")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .padding(.top, 40)

                    Text("코블링")
                        .font(.leeseoyun48)
                        .foregroundColor(Color(hex: "#2B3A1E"))

                    VStack(spacing: 6) {
                        Text("코블링과 함께하는 코딩 모험")
                        Text("지금 시작해요 !")
                    }
                    .font(.gmarketMedium16)
                    .foregroundColor(.black.opacity(0.65))
                }

                Spacer()

                Button {
                    onTapEmailSignup()
                    pushToEmailSignup = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                        Text("이메일로 가입하기").font(.gmarketMedium16)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)

                HStack(spacing: 6) {
                    Text("계정이 있으시다면")
                        .foregroundColor(.black.opacity(0.6))
                        .font(.gmarketMedium16)
                    Button { pushToLogin = true } label: {
                        Text("로그인")
                            .underline()
                            .foregroundColor(Color(hex: "#1E2A16"))
                            .font(.gmarketMedium16)
                    }
                }
                .padding(.bottom, 28)
            }
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
                EmailSignupView()
                    .environmentObject(authVM)
            }
        }
    }
}

#Preview {
    NavigationStack { // ✅ 프리뷰도 NavigationStack으로 감싸야 푸시가 보입니다.
        SignupView(onTapLogin: {}, onTapEmailSignup: {})
            .environmentObject(AuthViewModel())
    }
}
