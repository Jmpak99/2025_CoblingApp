//
//  BlockView.swift
//  Cobling
//

import SwiftUI

struct BlockView: View {
    @ObservedObject var block: Block
    var showChildren: Bool = true

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
                    // ✅ AnyGesture 적용
                    .gesture(dragGesture(geo: geo))
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

    // MARK: - Drag Gesture (🔥 타입 소거)
    private func dragGesture(geo: GeometryProxy) -> AnyGesture<DragGesture.Value> {

        // ✅ 시작 블록은 항상 고정
        if block.type == .start {
            return AnyGesture(DragGesture(minimumDistance: .infinity))
        }

        // ✅ 실행 중이면 전부 고정
        if viewModel.isExecuting {
            return AnyGesture(DragGesture(minimumDistance: .infinity))
        }

        // ✅ 일반 드래그
        return AnyGesture(
            DragGesture()
                .onChanged { value in
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
                    isDraggingLocal = false
                    dragOffset = .zero
                }
        )
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
