//
//  RepeatHeaderView.swift
//  Cobling
//
//  Created by 박종민 on 1/23/26.
//

import SwiftUI

struct RepeatHeaderView: View {
    @ObservedObject var block: Block
    private let options = [1, 2, 3, 4, 5]

    var body: some View {
        HStack {
            // =========================
            // 왼쪽: 반복 횟수 + 텍스트
            // =========================
            HStack(spacing: 6) {
                Picker(
                    "",
                    selection: Binding(
                        get: { Int(block.value ?? "1") ?? 1 },
                        set: { block.value = String($0) }
                    )
                ) {
                    ForEach(options, id: \.self) { count in
                        Text("\(count)")
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 42, height: 28)
                .background(Color.white)
                .cornerRadius(6)

                Text("번 반복하기")
                    .foregroundColor(.white)
                    .font(.system(size: 15, weight: .bold))
            }

            Spacer()

            // =========================
            // 오른쪽: 원형 아이콘
            // =========================
            ZStack {
                Circle()
                    .fill(Color.white)

                Image(systemName: "repeat")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#86B0FF"))
            }
            .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }
}
