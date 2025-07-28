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

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 12) {
                BlockView(block: startBlock)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(hex: "#F2F2F2"))
            .onChange(of: dragManager.isDragging) { dragging in
                if !dragging,
                   let end = dragManager.dragEndedAt,
                   let type = dragManager.draggingType {

                    let frame = geo.frame(in: .named("global"))
                    print("📍 드래그 종료 위치: \(end)")
                    print("🧱 조립 영역: \(frame)")

                    if frame.contains(end) {
                        let newBlock = Block(type: type)
                        startBlock.children.append(newBlock)
                        onDropBlock(type)
                        print("✅ 블록 추가됨")
                    } else {
                        print("❌ 블록이 영역 밖")
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
    static var previews: some View {
        let start = Block(type: .start)
        return BlockCanvasView(startBlock: start) { type in
            print("드롭한 블록 타입: \(type)")
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 300, height: 300)
    }
}
#endif
