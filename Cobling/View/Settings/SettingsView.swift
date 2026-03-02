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

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                // MARK: - 상단 타이틀
                Text("설정")
                    .font(.pretendardBold34)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // MARK: - 유저 정보 카드 (원하시면 유지/삭제 가능)
                userCard

                // MARK: - 추가 기능
                //sectionTitle("추가 기능")

                VStack(spacing: 0) {
//                    LockedToggleRow(
//                        iconSystemName: "lock",
//                        leadingSymbolSystemName: "rectangle.on.rectangle",
//                        title: "광고 노출",
//                        isOn: $isAdEnabled,
//                        locked: true
//                    )
//                    Divider().padding(.leading, 52)

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

//                    NavigationLink(destination: Text("나만의 네컷 홈페이지")) {
//                        ServiceRow(iconSystemName: "house", title: "나만의 네컷 홈페이지")
//                    }
//                    Divider().padding(.leading, 52)

                    NavigationLink(destination: ContributionThanksView()) {
                        ServiceRow(iconSystemName: "person.2", title: "코블링에 기여해주세요!")
                    }
                    Divider().padding(.leading, 52)

                    NavigationLink(destination: Text("개인정보 처리방침")) {
                        ServiceRow(iconSystemName: "person", title: "개인정보 처리방침")
                    }
                    Divider().padding(.leading, 52)

//                    NavigationLink(destination: Text("문의하기")) {
//                        ServiceRow(iconSystemName: "bubble.left", title: "문의하기")
//                    }

                    Divider().padding(.leading, 52)

                    // 버전 정보 (오른쪽에 회색 텍스트)
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22, weight: .regular))
                            .frame(width: 28)
                            .foregroundColor(.black)

                        Text("버전 정보")
                            .font(.system(size: 16))
                            .foregroundColor(.black)

                        Spacer()

                        Text(appVersionString)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .padding(.horizontal)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                
                // MARK: - 로그아웃 (스크롤 맨 아래)
                LogoutButtonPlain {
                    authVM.signOut()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        // 실제 빌드 버전 쓰고 싶으면 아래처럼 교체하셔도 됩니다.
        // let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        // let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        // return "\(v) (\(b))"
        "1.0.0v"
    }
}

// MARK: - 잠금 토글 Row (스크린샷의 “자물쇠 + 토글 비활성” 느낌)
private struct LockedToggleRow: View {
    let iconSystemName: String              // lock
    let leadingSymbolSystemName: String     // AD/프레임/탭바 아이콘 느낌
    let title: String
    @Binding var isOn: Bool
    let locked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconSystemName)
                .font(.system(size: 20, weight: .regular))
                .frame(width: 28)
                .foregroundColor(locked ? .black : .black)

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
                .disabled(locked)               // ✅ 잠금이면 비활성
                .opacity(locked ? 0.6 : 1.0)    // ✅ 스크린샷처럼 흐리게
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
    }
}

// MARK: - 서비스 정보 Row (왼쪽 아이콘 + 텍스트 + chevron)
private struct ServiceRow: View {
    let iconSystemName: String
    let title: String

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

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .padding(.horizontal, 12)
    }
}

// MARK: - 스크린샷과 동일한 “평면 텍스트” 로그아웃 버튼
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

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
