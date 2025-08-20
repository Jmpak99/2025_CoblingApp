//
//  EditProfileView.swift
//  Cobling
//
//  Created by 박종민 on 8/5/25.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tabBarViewModel: TabBarViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var nickname: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @State private var isSaving = false
    @State private var alertMessage: String?
    @State private var showAlert = false

    // MARK: - Validation
    private var isPasswordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    private var isPasswordValid: Bool {
        // 영어 소문자+숫자 포함 8자 이상
        let regex = "^(?=.*[a-z])(?=.*\\d)[a-z\\d]{8,}$"
        return password.isEmpty || NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password)
    }

    /// 닉네임만 있어도 저장 가능. 비번은 비어있거나(스킵) 유효/일치해야 함.
    private var isFormValid: Bool {
        !nickname.isEmpty && !isPasswordMismatch && isPasswordValid
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단 바
            HStack(spacing: 8) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
                Text("내 정보 수정")
                    .font(.pretendardBold34)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 24) {
                    Group {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("닉네임")
                                .font(.pretendardBold14)
                            TextField("이름을 입력하세요.", text: $nickname)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("이메일")
                                .font(.pretendardBold14)
                            TextField("이메일을 입력하세요", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("비밀번호")
                                .font(.pretendardBold14)
                            SecureField("영어소문자, 숫자 포함 8자 이상 (미입력 시 변경 안 함)", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))

                            if !password.isEmpty && !isPasswordValid {
                                Text("영어 소문자와 숫자를 포함해 8자 이상 입력해주세요.")
                                    .foregroundColor(.red)
                                    .font(.pretendardMedium14)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("비밀번호 확인")
                                .font(.pretendardBold14)
                            SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))

                            if isPasswordMismatch {
                                Text("비밀번호가 일치하지 않습니다.")
                                    .foregroundColor(.red)
                                    .font(.pretendardMedium14)
                            }
                        }
                    }

                    // 완료 버튼
                    Button(action: { Task { await onTapSave() } }) {
                        Text(isSaving ? "저장 중..." : "완료")
                            .foregroundColor(.black)
                            .font(.pretendardBold18)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color(hex: "#E9E8DD") : Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isSaving)
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            // 기존 프로필 값 프리필
            nickname = authVM.userProfile?.nickname ?? ""
            email = authVM.currentUserEmail ?? authVM.userProfile?.email ?? ""
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("알림"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("확인"), action: {
                // 성공 시 화면 닫기
                if alertMessage == "저장되었습니다." {
                    dismiss()
                }
            }))
        }
    }

    // MARK: - Actions
    private func onTapSave() async {
        isSaving = true
        defer { isSaving = false }
        do {
            // 1) 닉네임 업데이트 (필수)
            try await authVM.updateNickname(nickname)

            // 2) 이메일 변경 (선택)
            //    - 빈 값이 아니고 기존과 다를 때만 시도
            let currentEmail = authVM.currentUserEmail ?? authVM.userProfile?.email
            if !email.isEmpty, email != currentEmail {
                try await authVM.updateEmail(email)
            }

            // 3) 비밀번호 변경 (선택)
            if !password.isEmpty {
                try await authVM.updatePassword(password)
            }

            // 성공 안내
            alertMessage = "저장되었습니다."
            showAlert = true
        } catch {
            alertMessage = authVM.authError ?? error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(TabBarViewModel())
            .environmentObject(AuthViewModel())
    }
}
