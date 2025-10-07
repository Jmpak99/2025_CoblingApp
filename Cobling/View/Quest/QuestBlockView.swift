//
//  QuestBlockView.swift
//  Cobling
//

import SwiftUI

struct QuestBlockView: View {
    let chapterId: String
    let subQuestId: String

    @EnvironmentObject var tabBarViewModel: TabBarViewModel
    @StateObject private var dragManager = DragManager()
    @StateObject private var viewModel = QuestViewModel()
    @StateObject private var startBlock = Block(type: .start)
    @State private var paletteFrame: CGRect = .zero

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
        .onAppear {
            tabBarViewModel.isTabBarVisible = false
            // Firestore에서 SubQuest 불러오기
            viewModel.fetchSubQuest(chapterId: chapterId, subQuestId: subQuestId)
        }
        .onDisappear { tabBarViewModel.isTabBarVisible = true }
        .onChange(of: startBlock.children) { newChildren in
            viewModel.startBlock.children = newChildren
        }
        .animation(.easeInOut,
                   value: viewModel.showFailureDialog || viewModel.showSuccessDialog)
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.all, edges: .top)
    }

    @ViewBuilder
    private func mainContent() -> some View {
        VStack(spacing: 0) {
            if let subQuest = viewModel.subQuest {
                GameMapView(viewModel: viewModel, questTitle: subQuest.title)
                    .frame(height: 500)
            } else {
                ProgressView("불러오는 중...")
                    .frame(height: 500)
            }

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
                    .environmentObject(viewModel)
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
                        .ignoresSafeArea(.all, edges: .bottom)
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

#if DEBUG
struct QuestBlockView_Previews: PreviewProvider {
    static var previews: some View {
        QuestBlockView(chapterId: "chapter1", subQuestId: "subQuest1")
            .environmentObject(TabBarViewModel())
    }
}
#endif
