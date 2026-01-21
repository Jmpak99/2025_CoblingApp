//
//  BlockView.swift
//  Cobling
//

import SwiftUI

struct BlockView: View {
    @ObservedObject var block: Block
    var showChildren : Bool = true

    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel

    @State private var dragOffset: CGSize = .zero
    @State private var isDraggingLocal: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            GeometryReader { geo in
                Image(block.type.imageName)
                    .resizable()
                    .frame(width: blockSize.width, height: blockSize.height)
                    .scaleEffect(scale)
                    .opacity(currentOpacity)
                    .offset(dragOffset)
                    .animation(.easeInOut(duration: 0.2), value: currentOpacity)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // 🔥 이미 다른 블록이 드래그 주인이면 무시
                                if let ownerID = dragManager.draggingBlockID,
                                   ownerID != block.id {
                                    return
                                }

                                isDraggingLocal = true
                                dragOffset = value.translation

                                let frame = geo.frame(in: .global)
                                let position = CGPoint(
                                    x: frame.origin.x + value.location.x,
                                    y: frame.origin.y + value.location.y
                                )

                                // 🔥 최초 1회만 DragManager에 등록
                                if !dragManager.isDragging {
                                    dragManager.prepareDragging(
                                        type: block.type,
                                        at: position,
                                        offset: value.translation,
                                        block: block,
                                        source: .canvas
                                    )
                                }

                                dragManager.updateDragPosition(position)
                            }
                            .onEnded { _ in
                                // 🔥 여기서는 "로컬 드래그 상태만 종료"
                                isDraggingLocal = false
                                dragOffset = .zero

                                // ❌ finishDrag 호출하지 않음
                                // ❌ NotificationCenter 사용하지 않음
                            }
                    )
            }
            .frame(height: blockSize.height)

            // ======================
            // 자식 블록 (재귀)
            // ======================
            if showChildren && !block.children.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(block.children, id: \.id) { child in
                        BlockView(block: child, showChildren: true)
                            .environmentObject(dragManager)
                            .environmentObject(viewModel)
                    }
                }
                .padding(.leading, 20)
                .padding(.top, block.type == .start ? 2 : 0)
            }
        }
        .padding(1)
        .background(Color.clear)
    }

    // MARK: - UI Helpers

    private var blockSize: CGSize {
        switch block.type {
        case .start:
            return CGSize(width: 160, height: 50)
        default:
            return CGSize(width: 120, height: 30)
        }
    }

    private var isExecutingThisBlock: Bool {
        viewModel.currentExecutingBlockID == block.id
    }

    private var scale: CGFloat {
        (isDraggingLocal || isExecutingThisBlock) ? 1.05 : 1.0
    }

    private var currentOpacity: Double {
        if isDraggingLocal { return 0.8 }
        if viewModel.isExecuting && !isExecutingThisBlock { return 0.3 }
        return 1.0
    }
}
