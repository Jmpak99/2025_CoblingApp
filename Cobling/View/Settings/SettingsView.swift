//
//  SettingsView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

struct SettingsView: View {
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
                    // 수정 화면 이동
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex : "#E9E8DD"))
                .foregroundColor(.black)
                .cornerRadius(8)
                .font(.pretendardMedium14)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
            .padding(.horizontal)
            .padding(.bottom, 8)

            // 설정 메뉴 리스트
            List {
                SettingRow(title: "코블링 인스타그램")
                SettingRow(title: "알림 설정")
                SettingRow(title: "공지사항")
                SettingRow(title: "자주 묻는 질문")
                SettingRow(title: "앱 정보")
            }
            .listStyle(.plain)

            Spacer()
        }
    }
}

// MARK: - 단일 항목 컴포넌트
struct SettingRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
