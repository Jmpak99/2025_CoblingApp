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
        GeometryReader { blockGeo in
            let blockGlobal = blockGeo.frame(in: .named("global"))

            VStack(alignment: .leading, spacing: 0) {
                Image(block.type.imageName)
                    .resizable()
                    .frame(width: blockSize.width, height: blockSize.height)
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    .opacity(isDragging ? 0.8 : 1.0)
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let dragLocation = CGPoint(
                                    x: blockGlobal.origin.x + value.location.x,
                                    y: blockGlobal.origin.y + value.location.y
                                )
                                dragOffset = value.translation
                                isDragging = true

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
                                let dragLocation = CGPoint(
                                    x: blockGlobal.origin.x + value.location.x,
                                    y: blockGlobal.origin.y + value.location.y
                                )
                                isDragging = false
                                dragOffset = .zero
                                dragManager.endDragging(at: dragLocation)
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
        .frame(height: blockSize.height)
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
