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

    // 팔레트 영역 프레임
    @State private var paletteFrame: CGRect = .zero

    // 네비게이션 상태
    @State private var goToNextQuestId: String? = nil
    @State private var goBackToQuestList = false

    // MARK: - 팔레트 위에 있는지 판별 (삭제 표시용)
    private func isOverPalette() -> Bool {
        dragManager.isDragging &&
        dragManager.dragSource == .canvas &&
        paletteFrame.contains(dragManager.dragPosition)
    }

    var body: some View {
        ZStack {

            // ======================
            // 메인 콘텐츠
            // ======================
            VStack(spacing: 0) {

                // 게임 맵
                if let subQuest = viewModel.subQuest {
                    GameMapView(
                        viewModel: viewModel,
                        questTitle: subQuest.title
                    )
                    .frame(height: 500)
                } else {
                    ProgressView("불러오는 중...")
                        .frame(height: 500)
                }

                // ======================
                // 블록 영역
                // ======================
                HStack(spacing: 0) {

                    // ---------- 팔레트 ----------
                    GeometryReader { geo in
                        ZStack {

                            if isOverPalette() {
                                Color.red.opacity(0.3)
                                    .ignoresSafeArea(.container, edges: .bottom)
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
                                .environmentObject(viewModel)
                        }
                        .onAppear {
                            paletteFrame = geo.frame(in: .global)
                        }
                        .onChange(of: dragManager.dragPosition) { _ in
                            paletteFrame = geo.frame(in: .global)
                        }
                    }
                    .frame(width: 200)

                    // ---------- 캔버스 ----------
                    BlockCanvasView(
                        startBlock: startBlock,
                        paletteFrame: $paletteFrame
                    )
                    .environmentObject(dragManager)
                    .environmentObject(viewModel)
                    .background(Color.gray.opacity(0.1))
                }
            }

            // ======================
            // 👻 고스트 블록 (팔레트 → 캔버스만)
            // ======================
            if dragManager.isDragging,
               dragManager.dragSource == .palette,
               let type = dragManager.draggingType {

                GhostBlockView(
                    type: type,
                    position: dragManager.dragPosition,
                    offset: dragManager.dragStartOffset
                )
                .ignoresSafeArea()
                .zIndex(5)
            }

            // ======================
            // ❌ 실패 다이얼로그
            // ======================
            if viewModel.showFailureDialog {
                FailureDialogView {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        viewModel.showFailureDialog = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        viewModel.resetExecution()
                    }
                }
                .zIndex(10)
            }

            // ======================
            // ✅ 성공 다이얼로그
            // ======================
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
                            handleGoNext()
                        }
                    }
                )
                .zIndex(10)
            }
        }
        .environmentObject(dragManager)
        .environmentObject(viewModel)

        // =================================================
        // 🔥 드래그 종료 처리 (유일한 finishDrag 위치)
        // =================================================
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    dragManager.finishDrag(at: value.location) {
                        endPos, source, type, block in

                        guard !viewModel.isExecuting else { return }

                        // 1️⃣ 캔버스 → 팔레트 : 삭제
                        if source == .canvas,
                           let block = block,
                           paletteFrame.contains(endPos) {

                            startBlock.children.removeAll { $0.id == block.id }
                            return
                        }

                        // 2️⃣ 팔레트 → 캔버스 : 추가
                        if source == .palette,
                           let type = type,
                           dragManager.isOverCanvas {

                            let index = dragManager.canvasInsertIndex
                                ?? startBlock.children.count
                            startBlock.children.insert(Block(type: type), at: index)
                            return
                        }

                        // 3️⃣ 캔버스 → 캔버스 : 재정렬
                        if source == .canvas,
                           let block = block,
                           dragManager.isOverCanvas,
                           let fromIndex = startBlock.children.firstIndex(where: { $0.id == block.id }) {

                            let index = dragManager.canvasInsertIndex
                                ?? startBlock.children.count

                            if fromIndex == index || fromIndex + 1 == index { return }

                            startBlock.children.remove(at: fromIndex)
                            let adjusted = fromIndex < index ? index - 1 : index
                            startBlock.children.insert(block, at: adjusted)
                            return
                        }
                    }
                }
        )

        // ======================
        // 블록 변경 → ViewModel 반영
        // ======================
        .onChange(of: startBlock.children) { newChildren in
            viewModel.startBlock.children = newChildren
        }

        // ======================
        // 초기 로딩
        // ======================
        .onAppear {
            tabBarViewModel.isTabBarVisible = false
            viewModel.fetchSubQuest(
                chapterId: chapterId,
                subQuestId: subQuestId
            )
        }

        // ======================
        // 네비게이션
        // ======================
        .navigationDestination(item: $goToNextQuestId) { nextId in
            QuestBlockView(chapterId: chapterId, subQuestId: nextId)
        }

        .navigationDestination(isPresented: $goBackToQuestList) {
            QuestListView()
        }

        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.all, edges: .top)
    }

    // MARK: - 다음 퀘스트 이동
    private func handleGoNext() {
        viewModel.goToNextSubQuest { action in
            DispatchQueue.main.async {
                switch action {
                case .goToQuest(let nextId):
                    self.goToNextQuestId = nextId
                case .goToList, .waiting, .locked:
                    self.goBackToQuestList = true
                }
            }
        }
    }
}
