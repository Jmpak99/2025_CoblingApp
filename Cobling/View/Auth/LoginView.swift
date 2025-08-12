//
//  LoginView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

private enum DemoAuth {
    static let email = "demo@cobling.app"
    static let password = "cobling123"
}

struct LoginView: View {
    var onBack: () -> Void
    var onLoginSuccess: () -> Void
    var onTapSignup: () -> Void

    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF2DC").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                VStack(spacing: 16) {
                    Image("cobling_character_super")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.top, 16)

                    Text("코블링")
                        .font(.leeseoyun48)
                        .foregroundColor(Color(hex: "#2B3A1E"))
                }

                VStack(spacing: 12) {
                    CustomTextField(placeholder: "이메일주소", text: $email)
                    CustomSecureField(placeholder: "비밀번호", text: $password)

                    HStack {
                        Spacer()
                        Button { /* 비밀번호 재설정 */ } label: {
                            Text("비밀번호를 잊으셨나요?")
                                .font(.gmarketMedium14)
                                .underline()
                                .foregroundColor(Color(hex: "#2B3A1E"))
                        }
                    }
                    
                    Button {
                        email = DemoAuth.email
                        password = DemoAuth.password
                        authVM.debugSignIn()
                        onLoginSuccess()
                    } label: {
                        Text("테스트 계정으로 로그인")
                            .font(.gmarketMedium14)
                            .underline()
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 2)
                }
                
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Button {
                    guard !email.isEmpty, !password.isEmpty else { return }
                    isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isLoading = false
                        onLoginSuccess()
                    }
                } label: {
                    Text(isLoading ? "로그인 중..." : "로그인")
                        .font(.gmarketBold16)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#2F2F2F")))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.black.opacity(0.25), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Spacer()

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                HStack(spacing: 6) {
                    Text("계정이 없으신가요?")
                        .foregroundColor(Color(hex: "#25331B"))
                        .font(.gmarketMedium16)
                    Button { onTapSignup() } label: {
                        Text("가입하기")
                            .font(.gmarketBold16)
                            .foregroundColor(Color(hex: "#25331B"))
                    }
                }
                .padding(.bottom, 18)
            }
        }
        // ✅ 네비게이션 바는 표시(백 버튼 보임), 배경은 숨김 → 전체화면 느낌 유지
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        // 제목 숨기기(원하시면 유지 가능)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
    }
}

// 공용 입력 컴포넌트
private struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 14).frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.08)))
    }
}

private struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String
    var body: some View {
        SecureField(placeholder, text: $text)
            .padding(.horizontal, 14).frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.08)))
    }
}

#Preview {
    LoginView(onBack: {}, onLoginSuccess: {}, onTapSignup: {})
        .environmentObject(AuthViewModel()) // 프리뷰 크래시 방지
}
