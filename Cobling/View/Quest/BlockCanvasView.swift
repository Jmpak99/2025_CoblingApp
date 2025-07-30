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

                    if extendedPaletteFrame.contains(end),
                       let blockToRemove = dragManager.draggingBlock {
                        onRemoveBlock(blockToRemove)
                        print("🗑️ 삭제됨: \(blockToRemove.type)")
                    } else {
                        onDropBlock(type)
                        print("✅ 캔버스에 블록 추가됨: \(type)")
                    }

                    dragManager.reset()
                }
            }
        }
    }
}
