//
//  BlockView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//
import SwiftUI

struct BlockView: View {
    @ObservedObject var block: Block
    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel // ✅ 실행 상태를 위한 ViewModel 주입

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { blockGeo in
                Image(block.type.imageName)
                    .resizable()
                    .frame(width: blockSize.width, height: blockSize.height)
                    .scaleEffect(scale)
                    .opacity(currentOpacity) // ✅ 실행/드래그 상태 기반 투명도
                    .offset(dragOffset)
                    .animation(.easeInOut(duration: 0.25), value: currentOpacity)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                                isDragging = true
                                let blockGlobal = blockGeo.frame(in: .named("global"))
                                let dragLocation = CGPoint(
                                    x: blockGlobal.origin.x + value.location.x,
                                    y: blockGlobal.origin.y + value.location.y
                                )
                                dragManager.prepareDragging(
                                    type: block.type,
                                    at: dragLocation,
                                    offset: value.translation,
                                    block: block,
                                    source: .canvas
                                )
                                dragManager.updateDragPosition(dragLocation)
                                dragManager.startDragging()
                            }
                            .onEnded { value in
                                isDragging = false
                                dragOffset = .zero
                                let blockGlobal = blockGeo.frame(in: .named("global"))
                                let dragLocation = CGPoint(
                                    x: blockGlobal.origin.x + value.location.x,
                                    y: blockGlobal.origin.y + value.location.y
                                )
                                dragManager.endDragging(at: dragLocation)
                            }
                    )
            }
            .frame(height: blockSize.height)

            if !block.children.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(block.children, id: \.id) { child in
                        BlockView(block: child)
                            .environmentObject(dragManager)
                            .environmentObject(viewModel) // ✅ 자식에게도 전달
                    }
                }
                .padding(.leading, 20)
                .padding(.top, block.type == .start ? 2 : 0)
            }
        }
        .padding(1)
        .background(Color.clear)
    }

    // 블록 크기
    private var blockSize: CGSize {
        switch block.type {
        case .start:   return CGSize(width: 160, height: 50)
        default:       return CGSize(width: 120, height: 30)
        }
    }

    // ✅ 현재 실행 중인 블록인지 여부
    private var isExecutingThisBlock: Bool {
        viewModel.currentExecutingBlockID == block.id
    }

    // ✅ scale 효과: 드래그 시 or 실행 중인 블록일 때 강조
    private var scale: CGFloat {
        isDragging || isExecutingThisBlock ? 1.05 : 1.0
    }

    // ✅ opacity 설정 로직
    private var currentOpacity: Double {
        if isDragging {
            return 0.8
        } else if viewModel.isExecuting && !isExecutingThisBlock {
            return 0.3 // 실행 중이지만 이 블록이 아니면 어둡게
        } else {
            return 1.0 // 평소 or 실행 중인 블록
        }
    }
}
