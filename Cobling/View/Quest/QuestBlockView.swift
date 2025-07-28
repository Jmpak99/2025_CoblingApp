import SwiftUI

struct QuestBlockView: View {
    @StateObject private var dragManager = DragManager()
    @State private var startBlock = Block(type: .start)

    @State private var paletteFrame: CGRect = .zero
    
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
                    GeometryReader { geo in
                        BlockPaletteView()
                            .frame(width: 200)
                            .background(Color.white)
                            .onAppear {
                                paletteFrame = geo.frame(in: .named("global"))
                            }
                            .onChange(of: dragManager.dragPosition) { _ in
                                paletteFrame = geo.frame(in: .named("global"))
                            }
                    }
                    .frame(width: 200)

                    BlockCanvasView(
                        startBlock: startBlock,
                        onDropBlock: { droppedType in
                            let newBlock = Block(type: droppedType)
                            startBlock.children.append(newBlock)
                        },
                        onRemoveBlock: { removedBlock in
                            startBlock.children.removeAll { $0.id == removedBlock.id }
                        },
                        paletteFrame: $paletteFrame
                    )
                    .background(Color.gray.opacity(0.1))
                }

                if dragManager.isDragging,
                   let type = dragManager.draggingType, dragManager.dragSource == .palette {
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
