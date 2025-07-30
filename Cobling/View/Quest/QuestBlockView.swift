import SwiftUI

struct QuestBlockView: View {
    @StateObject private var dragManager = DragManager()
    @StateObject private var viewModel = QuestViewModel()
    @StateObject private var startBlock = Block(type: .start)
    @State private var paletteFrame: CGRect = .zero

    // 팔레트 위에 드래그 중인지 여부
    private func isOverPalette() -> Bool {
        paletteFrame.contains(dragManager.dragPosition)
            && dragManager.isDragging
            && dragManager.dragSource == .canvas
    }

    var body: some View {
        ZStack {
            mainContent()
            if viewModel.showFailureDialog {
                FailureDialogView {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        viewModel.showFailureDialog = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        viewModel.resetExecution()
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
            if viewModel.showSuccessDialog {
                SuccessDialogView(
                    onRetry: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            viewModel.showSuccessDialog = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            viewModel.resetExecution()
                        }
                    },
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            viewModel.showSuccessDialog = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            viewModel.resetExecution()
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onChange(of: startBlock.children) { newChildren in
            viewModel.startBlock.children = newChildren
        }
        .animation(.easeInOut, value: viewModel.showFailureDialog || viewModel.showSuccessDialog)
    }

    // MARK: - Main Content
    @ViewBuilder
    private func mainContent() -> some View {
        VStack(spacing: 0) {
            GameMapView(viewModel: viewModel)
                .frame(height: 500)
            ZStack {
                HStack(spacing: 0) {
                    paletteColumn()
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
                    .environmentObject(dragManager)
                }
                .coordinateSpace(name: "global")
                ghostBlockViewIfNeeded()
            }
            .environmentObject(dragManager)
        }
    }

    @ViewBuilder
    private func paletteColumn() -> some View {
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
            .onChange(of: dragManager.dragPosition) { _ in
                paletteFrame = geo.frame(in: .named("global"))
            }
        }
        .frame(width: 200)
    }

    @ViewBuilder
    private func ghostBlockViewIfNeeded() -> some View {
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
