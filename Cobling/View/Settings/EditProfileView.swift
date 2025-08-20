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

    // 탈퇴 다이얼로그/진행 상태
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

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
        ZStack {
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

                        // 완료 버튼 (성공 시 알림 없이 즉시 닫기)
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
                    .padding(.bottom, 120) // 하단 탈퇴 버튼과 간격 확보
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)

            // ✅ 커스텀 탈퇴 확인 다이얼로그 오버레이
            if showDeleteConfirm {
                ConfirmDialogView(
                    title: "정말 탈퇴하시겠어요?",
                    message: "계정과 데이터가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.",
                    primaryTitle: isDeleting ? "탈퇴 처리 중..." : "탈퇴",
                    secondaryTitle: "취소",
                    onPrimary: {
                        guard !isDeleting else { return }
                        Task { await onTapDelete() }
                    },
                    onSecondary: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            showDeleteConfirm = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            // 탭바 숨김
            tabBarViewModel.isTabBarVisible = false

            // 기존 프로필 값 프리필
            nickname = authVM.userProfile?.nickname ?? ""
            email = authVM.currentUserEmail ?? authVM.userProfile?.email ?? ""
        }
        .onDisappear {
            // 화면 닫힐 때 다시 보이기
            tabBarViewModel.isTabBarVisible = true
        }
        // 하단 빨간 "탈퇴하기" 버튼 (스크린샷 스타일)
        .safeAreaInset(edge: .bottom) {
            Text("탈퇴하기")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 18)                  // 터치 영역 확보
                .contentShape(Rectangle())               // 텍스트 주변까지 탭 가능
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeIn(duration: 0.15)) {
                        showDeleteConfirm = true
                    }
                }
                .padding(.bottom, 6)                     // 홈 인디케이터와 간격
        }
        // ⛔️ 오류일 때만 Alert 사용 (성공 시 Alert 사용 안 함)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("알림"),
                message: Text(alertMessage ?? ""),
                dismissButton: .default(Text("확인"))
            )
        }
    }

    // MARK: - Actions
    private func onTapSave() async {
        isSaving = true
        defer { isSaving = false }
        do {
            // 닉네임
            try await authVM.updateNickname(nickname)

            // 이메일(선택적)
            let currentEmail = authVM.currentUserEmail ?? authVM.userProfile?.email
            if !email.isEmpty, email != currentEmail {
                try await authVM.updateEmail(email)
            }

            // 비밀번호(선택적)
            if !password.isEmpty {
                try await authVM.updatePassword(password)
            }

            // ✅ 성공: 알림 없이 바로 종료
            await MainActor.run {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            }
        } catch {
            await MainActor.run {
                alertMessage = authVM.authError ?? error.localizedDescription
                showAlert = true
            }
        }
    }

    private func onTapDelete() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await authVM.deleteAccount() // AuthViewModel에 구현되어 있어야 합니다.

            // ✅ 성공: 다이얼로그 닫고 화면 즉시 종료 (알림 X)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.15)) {
                    showDeleteConfirm = false
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        } catch {
            await MainActor.run {
                alertMessage = authVM.authError ?? error.localizedDescription
                showAlert = true
            }
        }
    }
}

// 재사용 가능한 커스텀 확인 다이얼로그
struct ConfirmDialogView: View {
    let title: String
    let message: String?
    let primaryTitle: String      // 강조 버튼(예: 탈퇴)
    let secondaryTitle: String    // 취소
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    if let message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 16) {
                        // 취소
                        Button(action: onSecondary) {
                            Text(secondaryTitle)
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "EDEBE5"))
                                .cornerRadius(12)
                        }

                        // 강조(탈퇴) – 빨간색
                        Button(action: onPrimary) {
                            Text(primaryTitle)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 40)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 6)
            }
            .transition(.opacity.combined(with: .scale))
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(TabBarViewModel())
            .environmentObject(AuthViewModel())
    }
}
