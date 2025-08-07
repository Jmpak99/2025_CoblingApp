//
//  BlockCanvasView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//
import SwiftUI

struct BlockCanvasView: View {
    @ObservedObject var startBlock: Block
    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel
    var onDropBlock: (BlockType) -> Void
    var onRemoveBlock: (Block) -> Void
    @Binding var paletteFrame: CGRect

    @State private var prevBlockCount = 0

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    BlockView(block: startBlock)
                        .environmentObject(dragManager)
                        .environmentObject(viewModel)
                    Color.clear
                        .frame(height: 1)
                        .id("canvasBottom")
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
                .padding(.leading, 20) // 왼쪽 여백 추가
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .onChange(of: startBlock.children.count) { newCount in
                // "추가"될 때만 하단 자동 스크롤
                if newCount > prevBlockCount {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        scrollProxy.scrollTo("canvasBottom", anchor: .bottom)
                    }
                }
                prevBlockCount = newCount
            }
            .onAppear {
                prevBlockCount = startBlock.children.count
            }
            .onChange(of: dragManager.isDragging) { dragging in
                if !dragging,
                   let end = dragManager.dragEndedAt,
                   let type = dragManager.draggingType {
                    let extendedPaletteFrame = paletteFrame.insetBy(dx: -20, dy: -20)
                    if dragManager.dragSource == .canvas {
                        if extendedPaletteFrame.contains(end),
                           let blockToRemove = dragManager.draggingBlock {
                            onRemoveBlock(blockToRemove)
                        }
                    } else if dragManager.dragSource == .palette {
                        if !extendedPaletteFrame.contains(end) {
                            onDropBlock(type)
                        }
                    }
                    dragManager.reset()
                }
            }
        }
    }
}
