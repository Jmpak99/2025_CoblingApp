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

    var onDropBlock: (BlockType) -> Void
    var onRemoveBlock: (Block) -> Void
    @Binding var paletteFrame: CGRect

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                BlockView(block: startBlock)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(hex: "#F2F2F2"))
            .onChange(of: dragManager.isDragging) { dragging in
                if !dragging,
                   let end = dragManager.dragEndedAt,
                   let type = dragManager.draggingType {

                    let canvasArea = geo.frame(in: .named("global"))

                    if paletteFrame.contains(end) {
                        if let blockToRemove = dragManager.draggingBlock {
                            onRemoveBlock(blockToRemove)
                            print("🗑️ 삭제됨: \(type)")
                        }
                    } else if canvasArea.contains(end) {
                        onDropBlock(type) // ✅ 여기서만 추가 처리
                        print("✅ 블록 추가됨: \(type)")
                    }

                    dragManager.reset()
                }
            }
        }
    }
}

// MARK: - 미리보기
#if DEBUG
struct BlockCanvasView_Previews: PreviewProvider {
    @State static var dummyPaletteFrame: CGRect = .zero

    static var previews: some View {
        let start = Block(type: .start)
        return BlockCanvasView(
            startBlock: start,
            onDropBlock: { type in
                print("드롭한 블록 타입: \(type)")
            },
            onRemoveBlock: { block in
                print("제거한 블록: \(block)")
            },
            paletteFrame: $dummyPaletteFrame
        )
        .previewLayout(.sizeThatFits)
        .frame(width: 300, height: 300)
        .environmentObject(DragManager()) // 드래그도 필요하다면 추가
    }
}
#endif

