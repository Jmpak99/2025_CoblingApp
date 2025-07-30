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
            // 👉 최상위 BlockView에만 GeometryReader 적용
            GeometryReader { blockGeo in
                Image(block.type.imageName)
                    .resizable()
                    .frame(width: blockSize.width, height: blockSize.height)
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    .opacity(isDragging ? 0.8 : 1.0)
                    .offset(dragOffset)
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

            // 자식 블록: **GeometryReader 없이**
            if !block.children.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(block.children, id: \.id) { child in
                        BlockView(block: child)
                            .environmentObject(dragManager)
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
        case .start:   return CGSize(width: 160, height: 50)
        default:       return CGSize(width: 120, height: 30)
        }
    }
}
