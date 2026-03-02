//
//  SettingsView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isEditProfileActive = false

    // 토글 값(프리미엄 잠금이면 실제로는 변경 불가)
    @State private var isAdEnabled: Bool = false
    @State private var isOldFrameEnabled: Bool = false
    @State private var isHideTabBarEnabled: Bool = false

    // 플로팅 탭바 높이(프로젝트 값에 맞게)
    private let floatingTabBarHeight: CGFloat = 72

    // ✅ 로그아웃 확인 다이얼로그
    @State private var showLogoutConfirm = false
    @State private var isLoggingOut = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 18) {

                    // MARK: - 상단 타이틀
                    Text("설정")
                        .font(.pretendardBold34)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // MARK: - 유저 정보 카드
                    userCard

                    // MARK: - 추가 기능
                    // sectionTitle("추가 기능")
                    VStack(spacing: 0) {
//                        LockedToggleRow(
//                            iconSystemName: "lock",
//                            leadingSymbolSystemName: "rectangle.on.rectangle",
//                            title: "광고 노출",
//                            isOn: $isAdEnabled,
//                            locked: true
//                        )
//                        Divider().padding(.leading, 52)
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // MARK: - 서비스 정보
                    sectionTitle("서비스 정보")

                    VStack(spacing: 0) {
                        NavigationLink(destination: Text("코블링 인스타그램")) {
                            ServiceRow(iconSystemName: "camera", title: "코블링 인스타그램")
                        }
                        Divider().padding(.leading, 52)

                        NavigationLink(destination: ContributionThanksView()) {
                            ServiceRow(iconSystemName: "person.2", title: "코블링에 기여해주세요!")
                        }
                        Divider().padding(.leading, 52)

                        Link(
                            destination: URL(string: "https://certain-exoplanet-9bc.notion.site/Cobling-Privacy-Policy-31720a2218b1808783b3da4379d1ec9f?source=copy_link")!
                        ) {
                            ServiceRow(iconSystemName: "person", title: "개인정보 처리방침")
                        }
                        Divider().padding(.leading, 52)

                        // (원하시면 문의하기 등 추가)

                        Divider().padding(.leading, 52)

                        // ✅ 버전 정보도 동일한 서비스 Row 스타일로
                        ServiceRow(
                            iconSystemName: "info.circle",
                            title: "버전 정보",
                            trailingText: appVersionString,
                            showChevron: false
                        )
                    }
                    .padding(.horizontal)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // MARK: - 로그아웃 (스크롤 맨 아래)
                    LogoutButtonPlain {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeIn(duration: 0.15)) {
                            showLogoutConfirm = true
                        }
                    }
                    .padding(.top, 150)
                    .padding(.horizontal, 16)
                    .padding(.bottom, floatingTabBarHeight + 40)
                }
                .padding(.top, 8)
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarHidden(true)
            .background(Color.white)
            .disabled(showLogoutConfirm) // ✅ 팝업 떠 있을 때 뒤 터치/스크롤 막기(추천)

            // ✅ 커스텀 로그아웃 확인 다이얼로그 오버레이 (항상 화면 정중앙)
            if showLogoutConfirm {
                LogoutConfirmDialogView(
                    title: "로그아웃",
                    message: "정말 로그아웃 하시려구요",
                    primaryTitle: isLoggingOut ? "로그아웃 중..." : "로그아웃",
                    secondaryTitle: "취소",
                    onPrimary: {
                        guard !isLoggingOut else { return }
                        Task { await onTapLogout() }
                    },
                    onSecondary: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            showLogoutConfirm = false
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ 화면 전체 기준 중앙
                .ignoresSafeArea()                                  // ✅ 탭바/세이프영역 영향 제거
                .zIndex(999)                                        // ✅ 항상 최상단
                .transition(.opacity.combined(with: .scale))
            }
        }
    }

    // MARK: - 유저 카드
    private var userCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(!(authVM.userProfile?.nickname ?? "").isEmpty
                         ? (authVM.userProfile?.nickname ?? "")
                         : "닉네임을 설정해 주세요")
                        .font(.pretendardBold18)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(authVM.currentUserEmail ?? "이메일 없음")
                        .font(.pretendardMedium14)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button("내 정보 수정") {
                    isEditProfileActive = true
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(hex: "#E9E8DD"))
                .foregroundColor(.black)
                .cornerRadius(10)
                .font(.pretendardMedium14)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal)

            NavigationLink(destination: EditProfileView(), isActive: $isEditProfileActive) {
                EmptyView()
            }
            .hidden()
        }
    }

    // MARK: - 섹션 타이틀
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.pretendardBold18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)
    }

    // MARK: - 버전 스트링
    private var appVersionString: String {
        "1.0.0v"
    }

    // MARK: - 로그아웃 액션
    @MainActor
    private func onTapLogout() async {
        isLoggingOut = true
        defer { isLoggingOut = false }

        // 다이얼로그 닫기(UX)
        withAnimation(.easeOut(duration: 0.15)) {
            showLogoutConfirm = false
        }

        // 로그아웃
        authVM.signOut()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - 잠금 토글 Row (현재 미사용)
private struct LockedToggleRow: View {
    let iconSystemName: String
    let leadingSymbolSystemName: String
    let title: String
    @Binding var isOn: Bool
    let locked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconSystemName)
                .font(.system(size: 20, weight: .regular))
                .frame(width: 28)
                .foregroundColor(.black)

            Image(systemName: leadingSymbolSystemName)
                .font(.system(size: 20, weight: .regular))
                .frame(width: 24)
                .foregroundColor(locked ? .gray.opacity(0.7) : .black)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(locked ? .gray.opacity(0.7) : .black)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(locked)
                .opacity(locked ? 0.6 : 1.0)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
    }
}

// MARK: - 서비스 정보 Row
private struct ServiceRow: View {
    let iconSystemName: String
    let title: String

    var trailingText: String? = nil
    var showChevron: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconSystemName)
                .font(.system(size: 22, weight: .regular))
                .frame(width: 28)
                .foregroundColor(.black)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.black)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
    }
}

// MARK: - 로그아웃 버튼
private struct LogoutButtonPlain: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("로그아웃")
                Text("[→]")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.35))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 커스텀 로그아웃 확인 다이얼로그
private struct LogoutConfirmDialogView: View {
    let title: String
    let message: String?
    let primaryTitle: String
    let secondaryTitle: String
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

                        // 로그아웃
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
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
