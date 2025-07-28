import SwiftUI

struct QuestBlockView: View {
    @StateObject private var dragManager = DragManager()
    @State private var startBlock = Block(type: .start)
    
    // 캐릭터 위치와 맵 정보
    private let mapData: [[Int]] = [
        [1, 1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1]

    ]
    
    @State private var characterPosition = (row: 4, col: 0)

    var body: some View {
        VStack(spacing:0) {
            // MARK: - 게임 맵 뷰 (상단 영역)
            GameMapView(mapData: mapData,
                        characterPosition: characterPosition
            )
            .frame(height: 450)
            
            ZStack {
                HStack(spacing: 0) {
                    BlockPaletteView()
                        .frame(width: 200)

                    BlockCanvasView(
                        startBlock: startBlock,
                        onDropBlock: { droppedType in
                            let newBlock = Block(type: droppedType)
                            startBlock.children.append(newBlock)
                        }
                    )
                    .background(Color.gray.opacity(0.1))
                }

                // 고스트 블록이 드래그 중일 때만 표시
                if dragManager.isDragging,
                   let type = dragManager.draggingType,
                   dragManager.dragPosition != .zero {
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
