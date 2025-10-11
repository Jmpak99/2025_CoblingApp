//
//  BlockPaletteView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//

import SwiftUI

struct BlockPaletteView: View {
    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel   // ✅ DB 연동된 허용 블록 사용

    var body: some View {
        VStack(spacing: 12) {
            // ✅ DB에서 불러온 allowedBlocks만 표시
            ForEach(viewModel.allowedBlocks, id: \.self) { type in
                GeometryReader { geometry in
                    Image(type.imageName)
                        .resizable()
                        .frame(width: 120, height: 30)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let globalFrame = geometry.frame(in: .named("global"))
                                    let globalPoint = CGPoint(
                                        x: globalFrame.origin.x + value.location.x,
                                        y: globalFrame.origin.y + value.location.y
                                    )
                                    let offset = CGSize(
                                        width: value.startLocation.x - 80,
                                        height: value.startLocation.y - 20
                                    )
                                    dragManager.prepareDragging(
                                        type: type,
                                        at: globalPoint,
                                        offset: offset,
                                        source: .palette
                                    )
                                    dragManager.updateDragPosition(globalPoint)
                                    dragManager.startDragging()
                                }
                                .onEnded { value in
                                    let globalFrame = geometry.frame(in: .named("global"))
                                    let endPoint = CGPoint(
                                        x: globalFrame.origin.x + value.location.x,
                                        y: globalFrame.origin.y + value.location.y
                                    )
                                    dragManager.endDragging(at: endPoint)
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
