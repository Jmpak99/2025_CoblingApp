import SwiftUI

// BlockPaletteView.swift
struct BlockPaletteView: View {
    @EnvironmentObject var dragManager: DragManager
    
    private let blockTypes: [BlockType] = [
        .moveForward, .turnLeft, .turnRight
    ]
    
    var body: some View {
        ZStack {
            Color.white // 전체 배경 보장
            VStack(spacing: 12) {
                ForEach(blockTypes, id: \.self) { type in
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
                                        dragManager.prepareDragging(type: type, at: globalPoint, offset: offset)
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
                
                Spacer() // 아래 공간 채우기
            }
            .padding(.top, 16)
            .padding(.leading, 30)
            .padding(.trailing, 8)
        }
    }
    
}
