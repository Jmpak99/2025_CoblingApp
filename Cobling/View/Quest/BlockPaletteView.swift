//
//  BlockPaletteView.swift
//  Cobling
//

import SwiftUI

struct BlockPaletteView: View {
    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.allowedBlocks, id: \.self) { type in
                GeometryReader { geo in
                    Image(type.imageName)
                        .resizable()
                        .frame(width: 120, height: 30)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let frame = geo.frame(in: .global)
                                    let position = CGPoint(
                                        x: frame.origin.x + value.location.x,
                                        y: frame.origin.y + value.location.y
                                    )

                                    if !dragManager.isDragging {
                                        let offset = CGSize(
                                            width: value.startLocation.x - 80,
                                            height: value.startLocation.y - 20
                                        )
                                        dragManager.prepareDragging(
                                            type: type,
                                            at: position,
                                            offset: offset,
                                            block: nil,
                                            source: .palette
                                        )
                                    }

                                    dragManager.updateDragPosition(position)
                                }
                                .onEnded { _ in
                                    // 🔥 Palette에서는 드래그 종료 처리 ❌
                                    // Canvas가 finishDrag를 담당함
                                }
                        )
                }
                .frame(height: 40)
            }

            Spacer()
        }
        .padding(.top, 16)
        .padding(.leading, 30)
        .padding(.trailing, 8)
    }
}
