//
//  BlockView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//

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
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(block.type.imageName)
                .resizable()
                .frame(width: blockSize.width, height: blockSize.height)
                .overlay(
                    Group {
                        if let value = block.value, !value.isEmpty {
                            Text(value)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                        }
                    },
                    alignment: .trailing
                )
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .opacity(isDragging ? 0.8 : 1.0)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let globalPoint = CGPoint(
                                x: value.startLocation.x + value.translation.width,
                                y: value.startLocation.y + value.translation.height
                            )
                            dragOffset = value.translation
                            isDragging = true

                            // ✅ 드래그 출처를 .canvas로 명시!
                            dragManager.prepareDragging(
                                type: block.type,
                                at: globalPoint,
                                offset: .zero,
                                block: block,
                                source: DragSource.canvas
                            )
                            dragManager.updateDragPosition(globalPoint)
                            dragManager.startDragging()
                        }
                        .onEnded { value in
                            let end = CGPoint(
                                x: value.startLocation.x + value.translation.width,
                                y: value.startLocation.y + value.translation.height
                            )
                            isDragging = false
                            dragOffset = .zero
                            dragManager.endDragging(at: end)
                        }
                )

            if !block.children.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(block.children) { child in
                        BlockView(block: child)
                    }
                }
                .padding(.leading, 20)
                .padding(.top, block.type == .start ? 2 : 0)
            }
        }
        .padding(1)
        .background(Color.clear)
    }

    private var blockSize: CGSize {
        switch block.type {
        case .start:
            return CGSize(width: 160, height: 50)
        default:
            return CGSize(width: 120, height: 30)
        }
    }
}

// MARK: - 미리보기 Preview
#if DEBUG
struct BlockView_Previews: PreviewProvider {
    static var previews: some View {
        let start = Block(type: .start)
        start.children = [
            Block(type: .moveForward),
            Block(type: .turnLeft)
        ]

        return BlockView(block: start)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
            .environmentObject(DragManager())
    }
}
#endif
