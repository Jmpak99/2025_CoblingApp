//
//  BlockCanvasView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//
import SwiftUI

struct BlockCanvasView: View {
    @Binding var startBlock: Block
    @EnvironmentObject var dragManager: DragManager

    var onDropBlock: (BlockType) -> Void
    var onRemoveBlock: (Block) -> Void
    @Binding var paletteFrame: CGRect

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    BlockView(block: startBlock)
                    Spacer().frame(height: 80)
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .onChange(of: dragManager.isDragging) { dragging in
                if !dragging,
                   let end = dragManager.dragEndedAt,
                   let type = dragManager.draggingType {

                    let extendedPaletteFrame = paletteFrame.insetBy(dx: -20, dy: -20)

                    if dragManager.dragSource == .canvas {
                        // 캔버스에서 블록을 드래그한 경우
                        if extendedPaletteFrame.contains(end),
                           let blockToRemove = dragManager.draggingBlock {
                            // 팔레트 위에 놓으면 삭제
                            onRemoveBlock(blockToRemove)
                            print("🗑️ 삭제됨: \(blockToRemove.type)")
                        }
                        // 캔버스 위에 그냥 놓으면 아무 일도 안 함! (복사X)
                    } else if dragManager.dragSource == .palette {
                        // 팔레트에서 블록을 드래그한 경우만 새로 추가
                        if !extendedPaletteFrame.contains(end) {
                            onDropBlock(type)
                            print("✅ 캔버스에 블록 추가됨: \(type)")
                        }
                    }
                    dragManager.reset()
                }
            }
        }
    }
}
