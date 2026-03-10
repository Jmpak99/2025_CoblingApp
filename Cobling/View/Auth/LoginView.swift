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
    var onTapSignup: () -> Void  // 하단 “가입하기”에서 사인업으로 푸시

    /// 회원가입 직후 이메일 프리필(선택)
    var initialEmail: String? = nil

    // ⚠️ 바인딩처럼 쓰지 마세요: $authVM 금지
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorText: String? = nil

    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case email, password }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF2DC").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                // 상단 로고/타이틀
                VStack(spacing: 16) {
                    Image("cobling_stage_super")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.top, 16)

                    Text("코블링")
                        .font(.leeseoyun48)
                        .foregroundColor(Color(hex: "#2B3A1E"))
                }

                // 입력 영역
                VStack(spacing: 12) {
                    CustomTextField(placeholder: "이메일주소", text: $email)
                        .focused($focusedField, equals: .email)
                        .textContentType(.username)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    CustomSecureField(placeholder: "비밀번호", text: $password)
                        .focused($focusedField, equals: .password)
                        .textContentType(.password)
                        .onSubmit { Task { await tryLogin() } } // 리턴키로 로그인

                    HStack {
                        Spacer()
                        Button {
                            Task { await resetPassword() }
                        } label: {
                            Text("비밀번호를 잊으셨나요?")
                                .font(.gmarketMedium14)
                                .underline()
                                .foregroundColor(Color(hex: "#2B3A1E"))
                        }
                        .disabled(isLoading) // email.isEmpty일 때도 눌리게 변경
                    }

                    if let errorText {
                        Text(errorText)
                            .foregroundColor(.red)
                            .font(.gmarketMedium14)
                            .padding(.top, 2)
                    }

//                    // 데모 로그인 (실제 Firebase 이메일 / 비번 로그인)
//                    Button {
//                        Task { await signInDemo() }
//                    } label: {
//                        Text("테스트 계정으로 로그인")
//                            .font(.gmarketMedium14)
//                            .underline()
//                            .foregroundColor(.gray)
//                    }
//                    .padding(.top, 2)
//                    .disabled(isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                // 로그인 버튼
                Button {
                    Task { await tryLogin() }
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
                .disabled(!isFormValid || isLoading)
                .opacity((!isFormValid || isLoading) ? 0.6 : 1.0)
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Spacer()

                Divider()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)

                // 하단 가입 링크 → 사인업 푸시
                Button(action: { onTapSignup() }) {
                    HStack(spacing: 6) {
                        Text("계정이 없으신가요?")
                            .foregroundColor(Color(hex: "#25331B"))
                            .font(.gmarketMedium16)
                        Text("가입하기")
                            .font(.gmarketBold16)
                            .foregroundColor(Color(hex: "#25331B"))
                    }
                }
                .padding(.bottom, 18)
                .disabled(isLoading)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
        .onAppear {
            if let initialEmail, email.isEmpty {
                email = initialEmail
            }
        }
        .onDisappear { focusedField = nil }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Actions
    private func tryLogin() async {
        guard isFormValid else { return }
        errorText = nil
        isLoading = true
        let vm = authVM // 🧯 래퍼 혼동 방지용 로컬 캡처
        do {
            try await vm.signIn(email: email, password: password)
            onLoginSuccess()
        } catch {
            errorText = vm.authError ?? error.localizedDescription
        }
        isLoading = false
    }

    private func resetPassword() async {
        guard !email.isEmpty else {
            errorText = "비밀번호 재설정을 위해 이메일을 입력해 주세요."
            return
        }
        errorText = nil
        isLoading = true
        let vm = authVM // 🧯
        do {
            try await vm.resetPassword(email: email) // AuthViewModel에 이 함수가 구현되어 있어야 함
            errorText = "비밀번호 재설정 메일을 전송했습니다."
        } catch {
            errorText = vm.authError ?? error.localizedDescription
        }
        isLoading = false
    }

    /// 테스트 계정으로 실제 Firebase Login
    private func signInDemo() async {
        guard !isLoading else { return }
        errorText = nil
        isLoading = true
        let vm = authVM
        do {
            try await vm.signIn(email: DemoAuth.email, password: DemoAuth.password)
            await MainActor.run { onLoginSuccess() }
        } catch {
            await MainActor.run {
                errorText = vm.authError ?? error.localizedDescription
            }
        }
        isLoading = false
    }
}

// 공용 입력 컴포넌트
private struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.08))
            )
    }
}

private struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        SecureField(placeholder, text: $text)
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.08))
            )
    }
}

#Preview {
    NavigationStack {
        LoginView(
            onBack: {},
            onLoginSuccess: {},
            onTapSignup: {}
        )
        .environmentObject(AuthViewModel()) // 프리뷰 주입 필수
    }
}
