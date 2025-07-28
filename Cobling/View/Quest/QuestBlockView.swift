import SwiftUI

struct QuestBlockView: View {
    @StateObject private var dragManager = DragManager()
    @StateObject private var viewModel = QuestViewModel()

    @State private var startBlock = Block(type: .start)
    @State private var paletteFrame: CGRect = .zero

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                GameMapView(viewModel: viewModel)
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
                            startBlock: $startBlock,
                            onDropBlock: { droppedType in
                                let newBlock = Block(type: droppedType)
                                startBlock.children.append(newBlock)
                                print("✅ 블록 추가됨: \(newBlock.type)")
                            },
                            onRemoveBlock: { removedBlock in
                                startBlock.children.removeAll { $0.id == removedBlock.id }
                                print("🗑️ 블록 삭제됨: \(removedBlock.type)")
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

            // ✅ 실패 다이얼로그 오버레이
            if viewModel.showFailureDialog {
                FailureDialogView {
                    viewModel.resetExecution() // 실패 후 다시하기
                }
                .transition(.opacity)
            }

            // ✅ 성공 다이얼로그 오버레이
            if viewModel.showSuccessDialog {
                SuccessDialogView(
                    onRetry: {
                        viewModel.resetExecution() // 다시하기
                    },
                    onNext: {
                        print("➡️ 다음 퀘스트로 이동 예정") // 이후 확장
                        viewModel.resetExecution()
                    }
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
