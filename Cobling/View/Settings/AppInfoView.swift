//
//  AppInfoView.swift
//  Cobling
//
//  Created by 박종민 on 8/5/25.
//

import SwiftUI

struct AppInfoView: View {
    var body: some View {
        VStack(spacing: 0) {
            // 상단 타이틀
            HStack(spacing: 8) {
                Button(action: {
                    // 뒤로 가기 처리
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.top, 2)
                }

                Text("앱 정보")
                    .font(.pretendardBold34)
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 20)
            

            List {
                AppInfoRow(title: "버전정보")
                AppInfoRow(title: "앱스토어 후기쓰기")
                AppInfoRow(title: "앱 문의")
                AppInfoRow(title: "오픈소스 라이선스")
                AppInfoRow(title: "이용약관")
                AppInfoRow(title: "개인정보 처리방침")
            }
            .listStyle(.plain)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - 단일 항목 Row
struct AppInfoRow: View {
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
    NavigationStack {
        AppInfoView()
    }
}
