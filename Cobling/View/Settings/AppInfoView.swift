//
//  AppInfoView.swift
//  Cobling
//
//  Created by 박종민 on 8/5/25.
//

import SwiftUI

struct AppInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 타이틀
            HStack(spacing: 8) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.pretendardMedium18)
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
            
            // 버전정보일 경우 버전 텍스트 표시, 그 외는 chevron
            if title == "버전정보" {
                Text("v1.0.0")
                    .font(.pretendardMedium18)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
    }
    
    
    // 앱 버전 정보 동적으로 가져오기
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "v\(version)"
        }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AppInfoView()
    }
}
