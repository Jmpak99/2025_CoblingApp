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

    // 플로팅 탭바 높이(실제 높이에 맞게 조정하세요)
    private let floatingTabBarHeight: CGFloat = 72

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 상단 제목
                Text("설정")
                    .font(.pretendardBold34)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.top, .horizontal])
                    .padding(.bottom, 20)

                // 유저 정보 카드
                HStack(alignment: .center, spacing: 16) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        // 닉네임이 없으면 안내문 표시
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
                    .padding(.vertical, 6)
                    .background(Color(hex: "#E9E8DD"))
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .font(.pretendardMedium14)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.bottom, 8)

                NavigationLink(destination: EditProfileView(), isActive: $isEditProfileActive) {
                    EmptyView()
                }
                .hidden()

                // 설정 메뉴 리스트
                VStack(spacing: 0) {
                    NavigationLink(destination: Text("인스타그램으로 이동")) {
                        SettingRow(title: "코블링 인스타그램")
                    }
                    Divider().padding(.leading)

                    NavigationLink(destination: AppInfoView()) {
                        SettingRow(title: "앱 정보")
                    }
                    Divider().padding(.leading)
                }
                .padding(.horizontal)

                // 콘텐츠 끝 여백(버튼/탭바와 겹치지 않도록 충분히 확보)
                Color.clear.frame(height: floatingTabBarHeight + 120)
            }
        }
        // ⬇️ 하단 오버레이: 플로팅 탭바 위로 확실히 보이게
        .overlay(alignment: .bottom) {
            LogoutButtonPlain {
                authVM.signOut()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, floatingTabBarHeight + 8) // 탭바 높이만큼 위로 올림
            .zIndex(2) // 탭바보다 위에
        }
        .ignoresSafeArea(.keyboard)
    }
}

// 스크린샷과 동일한 “평면 텍스트” 로그아웃 버튼
private struct LogoutButtonPlain: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("로그아웃")
                Text("[→]")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.35)) // 연한 회색 텍스트
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12) // 터치 영역
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain) // 배경/하이라이트 제거
    }
}

// 단일 항목 컴포넌트
struct SettingRow: View {
    let title: String
    var showArrow: Bool = true

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.black)
            Spacer()
            if showArrow {
                Image(systemName: "chevron.right")
                    .resizable()
                    .frame(width: 6, height: 12)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
