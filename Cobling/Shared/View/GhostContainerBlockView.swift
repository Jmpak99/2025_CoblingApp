//
//  Container.swift
//  Cobling
//
//  Created by 박종민 on 1/23/26.
//

import SwiftUI

/// 캔버스 ContainerBlockView와 레이아웃이 완전히 동일한 고스트 반복문 블록
struct GhostContainerBlockView: View {

    let block: Block
    let position: CGPoint

    private let blockWidth: CGFloat = 165
    private let leftBarWidth: CGFloat = 12
    private let previewCount = 3
    
    // IfHeaderView에 options/defaultCondition 주려면 ViewModel 필요
    @EnvironmentObject var viewModel: QuestViewModel
    
    // 컨테이너 타입에 따라 색상 분기 (repeat / if / ifElse)
    private var containerTint: Color {
        switch block.type {
        case .repeatCount, .repeatForever:
            return Color(hex: "#86B0FF")      // repeat 계열
        case .if, .ifElse:
            return Color(hex: "#4CCB7A")      // if 계열
        default:
            return Color(hex: "#86B0FF")
        }
    }
    
    // 컨테이너 타입에 따라 헤더 뷰 분기 + IfHeaderView 파라미터 전달
    @ViewBuilder
    private var ghostHeaderView: some View {
        switch block.type {
        case .repeatCount, .repeatForever:
            RepeatHeaderView(block: block)

        case .if, .ifElse:
            // 에러 원인 해결: options, defaultCondition 전달
            IfHeaderView(
                block: block,
                options: viewModel.currentAllowedIfConditions,
                defaultCondition: viewModel.currentDefaultIfCondition
            )

        default:
            RepeatHeaderView(block: block)
        }
    }


    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // =========================
            // 왼쪽 세로 바 (캔버스와 동일)
            // =========================
            Rectangle()
                .fill(containerTint)
                .frame(width: leftBarWidth)
                .clipShape(
                    RoundedCorner(
                        radius: 12,
                        corners: [.topLeft, .bottomLeft]
                    )
                )

            VStack(alignment: .leading, spacing: 6) {

                // =========================
                // 반복문 헤더 (캔버스와 동일)
                // =========================
                ghostHeaderView
                    .frame(width: blockWidth, height: 36)
                    .background(
                        containerTint
                            .clipShape(
                                RoundedCorner(
                                    radius: 18,
                                    corners: [.topRight, .bottomRight]
                                )
                            )
                    )

                // =========================
                // 내부 블록 미리보기
                // =========================
                VStack(alignment: .leading, spacing: 6) {

                    ForEach(block.children.prefix(previewCount)) { child in
                        GhostInnerBlockView(type: child.type)
                    }

                    if block.children.count > previewCount {
                        Text("⋯")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(containerTint)
                            .padding(.leading, 8)
                    }
                }
                .padding(.leading, 6)

                // =========================
                // 하단 캡 (캔버스와 동일)
                // =========================
                Rectangle()
                    .fill(containerTint)
                    .frame(width: 100, height: 12)
                    .clipShape(
                        RoundedCorner(
                            radius: 6,
                            corners: [.topRight, .bottomRight]
                        )
                    )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .opacity(0.55)
        .shadow(radius: 6)
        .position(position)
        .allowsHitTesting(false)
    }
}

struct GhostInnerBlockView: View {
    let type: BlockType

    var body: some View {
        Image(type.imageName)
            .resizable()
            .frame(width: 120, height: 30)
            .opacity(0.7)
    }
}
