//
//  SettingsView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var isEditProfileActive = false
    
    
    var body: some View {
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
                    Text("유저 이름")
                        .font(.pretendardBold18)
                    Text("가입메일")
                        .font(.pretendardMedium14)
                        .foregroundColor(.gray)
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

            // 설정 메뉴 리스트 (VStack으로 커스터마이징)
            VStack(spacing: 0) {
                NavigationLink(destination: Text("인스타그램으로 이동")) {
                    SettingRow(title: "코블링 인스타그램")
                }
                Divider()
                    .padding(.leading)

                NavigationLink(destination: AppInfoView()) {
                    SettingRow(title: "앱 정보")
                }
                Divider()
                    .padding(.leading)
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Spacer()
        }
    }
}

// MARK: - 단일 항목 컴포넌트
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
        .contentShape(Rectangle()) // 탭 가능한 영역 확장
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView()
    }
}
