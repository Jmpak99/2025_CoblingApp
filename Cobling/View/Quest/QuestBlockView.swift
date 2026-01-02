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

    // ✅ 네비게이션/알럿 상태
    @State private var goToNextQuestId: String? = nil
    @State private var showLockedAlert = false
    @State private var showWaitingAlert = false
    @State private var goBackToQuestList = false

    // ✅ waiting(서버 반영 대기) 오버레이
    @State private var isWaitingOverlay = false

    // ✅ waiting 재시도 카운트
    @State private var waitingRetryCount = 0

    private func isOverPalette() -> Bool {
        paletteFrame.contains(dragManager.dragPosition)
        && dragManager.isDragging
        && dragManager.dragSource == .canvas
    }

    var body: some View {
        ZStack {
            mainContent()

            // ✅ 서버 반영 대기 오버레이
            if isWaitingOverlay {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("챕터 여는 중입니다…")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(18)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(14)
                    )
                    .zIndex(20)
            }

            // 실패 다이얼로그
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

            // 성공 다이얼로그
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
                            // ✅ 다음으로: waiting 처리
                            waitingRetryCount = 0
                            isWaitingOverlay = true
                            tryGoNextHandlingWaiting()
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onAppear {
            tabBarViewModel.isTabBarVisible = false

            // ✅ (중요) 진입 게이트: locked면 기다렸다가 열리면 fetch
            isWaitingOverlay = true
            viewModel.ensureSubQuestAccessible(chapterId: chapterId, subQuestId: subQuestId) { action in
                DispatchQueue.main.async {
                    switch action {
                    case .goToQuest:
                        self.isWaitingOverlay = false
                        self.viewModel.fetchSubQuest(chapterId: chapterId, subQuestId: subQuestId)

                    case .waiting:
                        // 너무 오래 걸리면 안내만 하고 화면 유지(홈으로 튕기지 않음)
                        self.isWaitingOverlay = false
                        self.showWaitingAlert = true

                    case .locked:
                        self.isWaitingOverlay = false
                        self.showLockedAlert = true

                    case .goToList:
                        self.isWaitingOverlay = false
                        self.goBackToQuestList = true
                    }
                }
            }
        }
        .onDisappear {
            tabBarViewModel.isTabBarVisible = true
        }
        .onChange(of: startBlock.children) { newChildren in
            viewModel.startBlock.children = newChildren
        }
        .animation(.easeInOut,
                   value: viewModel.showFailureDialog || viewModel.showSuccessDialog)
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.all, edges: .top)

        // ✅ 다음 퀘스트 네비게이션
        .navigationDestination(item: $goToNextQuestId) { nextId in
            QuestBlockView(chapterId: chapterId, subQuestId: nextId)
        }

        // ✅ 퀘스트 리스트 복귀
        .navigationDestination(isPresented: $goBackToQuestList) {
            QuestListView()
        }

        // ✅ 진짜 잠김 알럿
        .alert("🔒 잠긴 퀘스트입니다", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("선행 퀘스트를 먼저 완료해 주세요.")
        }

        // ✅ waiting 알럿
        .alert("⏳ 챕터를 여는 중이에요", isPresented: $showWaitingAlert) {
            Button("재시도") {
                isWaitingOverlay = true
                viewModel.ensureSubQuestAccessible(chapterId: chapterId, subQuestId: subQuestId) { action in
                    DispatchQueue.main.async {
                        switch action {
                        case .goToQuest:
                            self.isWaitingOverlay = false
                            self.viewModel.fetchSubQuest(chapterId: chapterId, subQuestId: subQuestId)
                        case .waiting:
                            self.isWaitingOverlay = false
                            self.showWaitingAlert = true
                        case .locked:
                            self.isWaitingOverlay = false
                            self.showLockedAlert = true
                        case .goToList:
                            self.isWaitingOverlay = false
                            self.goBackToQuestList = true
                        }
                    }
                }
            }
            Button("확인", role: .cancel) { }
        } message: {
            Text("서버 반영이 지연되고 있어요.\n잠시 후 다시 시도해 주세요.")
        }
    }

    // MARK: - 다음으로(Waiting 포함)
    private func tryGoNextHandlingWaiting() {
        viewModel.goToNextSubQuest { action in
            DispatchQueue.main.async {
                switch action {
                case .goToQuest(let nextId):
                    self.isWaitingOverlay = false
                    self.goToNextQuestId = nextId

                case .goToList:
                    self.isWaitingOverlay = false
                    self.goBackToQuestList = true

                case .waiting:
                    self.waitingRetryCount += 1
                    let maxRetry = 6
                    let delay: Double = 0.6

                    if self.waitingRetryCount <= maxRetry {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.tryGoNextHandlingWaiting()
                        }
                    } else {
                        self.isWaitingOverlay = false
                        self.showWaitingAlert = true
                    }

                case .locked:
                    self.isWaitingOverlay = false
                    self.showLockedAlert = true
                }
            }
        }
    }

    // MARK: - 메인 UI
    @ViewBuilder
    private func mainContent() -> some View {
        VStack(spacing: 0) {
            if let subQuest = viewModel.subQuest {
                GameMapView(viewModel: viewModel, questTitle: subQuest.title)
                    .frame(height: 500)
            } else {
                // ✅ 진입 게이트 통과 전에는 오버레이가 떠 있으므로 간단 처리
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

    // MARK: - 팔레트 컬럼
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
                    .environmentObject(viewModel)
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

    // MARK: - 고스트 블록
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
        QuestBlockView(chapterId: "ch1", subQuestId: "sq1")
            .environmentObject(TabBarViewModel())
    }
}
#endif
