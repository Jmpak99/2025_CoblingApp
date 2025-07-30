import SwiftUI

struct QuestBlockView: View {
    @StateObject private var dragManager = DragManager()
    @StateObject private var viewModel = QuestViewModel()

    @State private var startBlock = Block(type: .start)
    @State private var paletteFrame: CGRect = .zero

    // 팔레트위에 올려진 상태 여부
    private func isOverPalette() -> Bool {
        print(
            "isDragging:", dragManager.isDragging,
            "dragSource:", dragManager.dragSource,
            "dragPosition:", dragManager.dragPosition,
            "paletteFrame:", paletteFrame,
            "-> contains:", paletteFrame.contains(dragManager.dragPosition)
        )
        return dragManager.isDragging &&
            dragManager.dragSource == .canvas &&
            paletteFrame.contains(dragManager.dragPosition)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                GameMapView(viewModel: viewModel)
                    .frame(height: 500)

                ZStack {
                    HStack(spacing: 0) {
                        GeometryReader { geo in
                            ZStack {
                                if isOverPalette() {
                                    Color.red.opacity(0.3)
                                        .overlay(
                                            Text("삭제")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        )
                                } else {
                                    Color.white
                                }
                                BlockPaletteView()
                                    .environmentObject(dragManager)
                            }
                            .onAppear {
                                paletteFrame = geo.frame(in: .named("global"))
                            }
                            .onChange(of: dragManager.dragPosition) {
                                paletteFrame = geo.frame(in: .named("global"))
                            }

                        }
                        .frame(width: 200)


                        BlockCanvasView(
                            startBlock: $startBlock,
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
                       let type = dragManager.draggingType,
                       dragManager.dragSource == .palette {
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

            if viewModel.showFailureDialog {
                FailureDialogView {
                    viewModel.resetExecution()
                }
                .transition(.opacity)
            }
            if viewModel.showSuccessDialog {
                SuccessDialogView(
                    onRetry: { viewModel.resetExecution() },
                    onNext: { viewModel.resetExecution() }
                )
                .transition(.opacity)
            }
        }
        .onChange(of: startBlock.children) { newChildren in
            viewModel.startBlock.children = newChildren
        }
        .animation(.easeInOut, value: viewModel.showFailureDialog || viewModel.showSuccessDialog)
    }
}


// MARK: - Preview
#if DEBUG
struct QuestBlockView_Previews: PreviewProvider {
    static var previews: some View {
        QuestBlockView()
            .previewLayout(.device)
            .previewDisplayName("블록코딩 미리보기")
            .frame(width: 430, height: 932)
    }
}
#endif
