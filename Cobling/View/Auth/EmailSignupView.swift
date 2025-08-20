//
//  EmailSignupView.swift
//  Cobling
//
//  Created by 박종민 on 8/9/25.
//


import SwiftUI

struct EmailSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel

    // ✅ 가입 성공 시 부모에서 네비 전환을 처리할 콜백
    var onSignupSuccess: () -> Void = {}

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @State private var errorText: String?

    private let fieldHeight: CGFloat = 48
    private let fieldRadius: CGFloat = 10

    private var isFormValid: Bool {
        !name.isEmpty && email.contains("@") && password.count >= 8 && password == confirm
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 타이틀
                    VStack(alignment: .leading, spacing: 8) {
                        Text("프로필")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                        Text("가입하는 분의 프로필을 입력해주세요.")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.45))
                    }
                    .padding(.top, 8)

                    Group {
                        fieldLabel("이름")
                        inputTextField("이름을 입력하세요.", text: $name)

                        fieldLabel("이메일")
                        inputTextField("email@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)

                        fieldLabel("비밀번호")
                        inputSecureField("영어소문자, 숫자 포함 8자 이상", text: $password)

                        fieldLabel("비밀번호 확인")
                        inputSecureField("영어소문자, 숫자 포함 8자 이상", text: $confirm)
                    }

                    if let e = errorText {
                        Text(e).font(.system(size: 13)).foregroundColor(.red)
                    }

                    (
                        Text("가입을 완료하실 경우 ")
                            .foregroundColor(.black.opacity(0.65))
                        + Text("코블링의 이용약관 및 개인정보처리방침")
                            .underline()
                            .foregroundColor(Color(hex: "#6B8F5D"))
                        + Text("에 동의하는 것으로 간주합니다.")
                            .foregroundColor(.black.opacity(0.65))
                    )
                    .font(.system(size: 12))

                    Button {
                        Task { await signUp() }
                    } label: {
                        Text(isLoading ? "가입 중..." : "가입하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#2F2F2F")))
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity((!isFormValid || isLoading) ? 0.6 : 1.0)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
    }

    // Subviews
    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 14, weight: .semibold)).foregroundColor(.black).padding(.top, 2)
    }
    private func inputTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(.horizontal, 14).frame(height: fieldHeight)
            .background(RoundedRectangle(cornerRadius: fieldRadius).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: fieldRadius).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }
    private func inputSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding(.horizontal, 14).frame(height: fieldHeight)
            .background(RoundedRectangle(cornerRadius: fieldRadius).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: fieldRadius).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    // Action
    private func signUp() async {
        errorText = nil
        isLoading = true
        do {
            try await authVM.signUp(email: email, password: password, nickname: name)
            onSignupSuccess() // ✅ 가입 성공 → 부모가 로그인 화면으로 넘김
        } catch {
            errorText = authVM.authError ?? error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    EmailSignupView()
        .environmentObject(AuthViewModel())
}
