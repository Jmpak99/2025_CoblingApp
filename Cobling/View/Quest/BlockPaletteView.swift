import SwiftUI

/// 좌측 블록 팔레트 뷰 - 이동 블록을 드래그하여 생성 가능
struct BlockPaletteView: View {
    @EnvironmentObject var dragManager: DragManager

    private let blockTypes: [BlockType] = [
        .moveForward, .turnLeft, .turnRight
    ]

    var body: some View {
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

                                    let movement = hypot(value.translation.width, value.translation.height)
                                    guard globalPoint != .zero else { return }

                                    let offset = CGSize(
                                        width: value.startLocation.x - 80,
                                        height: value.startLocation.y - 20
                                    )

                                    dragManager.prepareDragging(type: type, at: globalPoint, offset: offset)

                                    DispatchQueue.main.async {
                                        dragManager.startDragging()
                                    }
                                }
                                .onEnded { _ in
                                    dragManager.endDragging()
                                }
                        )

                }
                .frame(height: 40)
            }
        }
        .padding()
        .background(Color.white)
    }
}
