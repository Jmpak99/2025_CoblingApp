//
//  RepeatHeaderView.swift
//  Cobling
//
//  Created by 박종민 on 1/23/26.
//

import SwiftUI

struct RepeatHeaderView: View {
    @ObservedObject var block: Block
    private let options = [1, 2, 3, 4, 5, 6, 7, 8, 9 ,10]

    var body: some View {
        HStack {
            // =========================
            // 왼쪽: 반복 횟수 + 텍스트
            // =========================
            HStack(spacing: 6) {
                Menu {
                    ForEach(options, id: \.self) { count in
                        Button {
                            block.value = String(count)
                        } label: {
                            Text("\(count)")
                                .font(.pretendardMedium14)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        // 숫자
                        Text(block.value ?? "1")
                            .font(.pretendardMedium14) // ✅ 숫자 크기 제어
                            .foregroundColor(.black)

                        // ▼ 화살표
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50, height: 28)
                    .background(Color.white)
                    .cornerRadius(6)
                }
                .padding(.leading, -12)

                Text("번 반복하기")
                    .foregroundColor(.white)
                    .font(.pretendardMedium14)
            }

            Spacer()

            // =========================
            // 오른쪽: 원형 아이콘
            // =========================
            ZStack {
                Circle()
                    .fill(Color.white)

                Image(systemName: "repeat")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#86B0FF"))
            }
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }
}
