import SwiftUI

struct QuestBlockView: View {
    @StateObject private var dragManager = DragManager()
    @State private var startBlock = Block(type: .start)

    private let mapData: [[Int]] = [
        [1, 1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1]
    ]
    @State private var characterPosition = (row: 4, col: 0)

    var body: some View {
        VStack(spacing: 0) {
            GameMapView(mapData: mapData, characterPosition: characterPosition)
                .frame(height: 450)

            ZStack {
                HStack(spacing: 0) {
                    BlockPaletteView()
                        .frame(width: 200)

                    BlockCanvasView(startBlock: startBlock) { droppedType in
                        print("드롭된 블록: \(droppedType)")
                    }
                }

                if dragManager.isDragging,
                   let type = dragManager.draggingType {
                    GhostBlockView(
                        type: type,
                        position: dragManager.dragPosition,
                        offset: dragManager.dragStartOffset
                    )
                }
            }
            .environmentObject(dragManager)
            .coordinateSpace(name: "global")
        }
    }
}

// MARK: - 미리보기
#if DEBUG
struct QuestBlockView_Previews: PreviewProvider {
    static var previews: some View {
        QuestBlockView()
            .previewLayout(.device)
            .previewDisplayName("블록코딩 미리보기")
            .frame(width: 430, height: 932) // iPhone 14 Pro Max 사이즈
    }
}
#endif
