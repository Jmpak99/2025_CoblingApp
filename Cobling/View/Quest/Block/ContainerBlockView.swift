//
//  ContainerBlockView.swift
//  Cobling
//
//  Created by 박종민 on 1/23/26.
//

import SwiftUI

struct ContainerBlockView: View {
    @ObservedObject var block: Block

    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel

    private let blockWidth: CGFloat = 165
    private let leftBarWidth: CGFloat = 12

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // =========================
            // 왼쪽 세로 바
            // =========================
            Rectangle()
                .fill(Color(hex: "#86B0FF"))
                .frame(width: leftBarWidth)
                .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .bottomLeft]))

            VStack(alignment: .leading, spacing: 6) {

                // =========================
                // 2️⃣ 헤더 (오른쪽 상단만 둥글게)
                // =========================
                RepeatHeaderView(block: block)
                    .frame(width: blockWidth, height: 36)
                    .background(
                        Color(hex: "#86B0FF")
                            .clipShape(
                                RoundedCorner(
                                    radius: 18,
                                    corners: [.topRight, .bottomRight]
                                )
                            )
                    )

                // =========================
                // 3️⃣ 내부 영역 (투명)
                // =========================
                VStack(alignment: .leading, spacing: 6) {
                    if block.children.isEmpty {
                        Text("여기에 블록을 넣어주세요")
                            .font(.pretendardBold14)
                            .foregroundColor(Color(hex : "ACC9FF"))
                            .padding(.vertical, 4)
                    } else {
                        ForEach(block.children) { child in
                            BlockView(block: child)
                                .environmentObject(dragManager)
                                .environmentObject(viewModel)
                        }
                    }
                }
                .padding(.leading, 6)

                // =========================
                // 4️⃣ 하단 캡 (오른쪽 하단만 둥글게)
                // =========================
                Rectangle()
                    .fill(Color(hex: "#86B0FF"))
                    .frame(width: 100, height: 12)
                    .clipShape(
                        RoundedCorner(
                            radius: 6,
                            corners: [.topRight, .bottomRight]
                        )
                    )
            }
        }
        .padding(.bottom, 2)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

