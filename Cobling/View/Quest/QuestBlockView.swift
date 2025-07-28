import SwiftUI

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

            // ✅ 실패 시 다이얼로그 오버레이 표시
            if viewModel.showFailureDialog {
                let retryAction = {
                    viewModel.resetExecution() // 다시하기 눌렀을 때 초기화
                }

                FailureDialogView(onRetry: retryAction)
                    .transition(.opacity)
            }
        }
        // ✅ ViewModel과 동기화
        .onChange(of: startBlock.children) { newChildren in
            viewModel.startBlock.children = newChildren
        }
        .animation(.easeInOut, value: viewModel.showFailureDialog)
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
