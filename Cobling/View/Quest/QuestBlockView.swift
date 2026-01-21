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

    // MARK: - 팔레트 위에 있는지 판별 (삭제 영역 표시용)
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

                            // 🔥 삭제 오버레이 (하단 SafeArea까지)
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

        // ======================
        // 🔥 드래그 종료 이벤트
        // ======================

        // 팔레트 → 캔버스 : 추가
        .onReceive(NotificationCenter.default.publisher(for: .finishDragFromPalette)) { noti in
            guard
                let payload = noti.object as? (CGPoint, DragSource, BlockType?, Block?),
                let type = payload.2
            else { return }

            startBlock.children.append(Block(type: type))
        }

        // 캔버스 → 팔레트 : 삭제
        .onReceive(NotificationCenter.default.publisher(for: .finishDragFromCanvas)) { noti in
            guard
                let payload = noti.object as? (CGPoint, DragSource, BlockType?, Block?),
                let block = payload.3
            else { return }

            let endPoint = payload.0
            let source   = payload.1

            if source == .canvas,
               paletteFrame.contains(endPoint) {

                startBlock.children.removeAll { $0.id == block.id }
            }
        }

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
