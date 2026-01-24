//
//  QuestBlockView.swift
//  Cobling
//

import SwiftUI

struct QuestBlockView: View {
    let chapterId: String
    let subQuestId: String

    @EnvironmentObject var tabBarViewModel: TabBarViewModel
    @EnvironmentObject var appState: AppState

    @StateObject private var dragManager = DragManager()
    @StateObject private var viewModel = QuestViewModel()

    // 팔레트 영역 프레임
    @State private var paletteFrame: CGRect = .zero

    // 네비게이션 상태
    @State private var goToNextQuestId: String? = nil
    @State private var goBackToQuestList = false
    
    // waiting / locked 상태
        @State private var isWaitingOverlay = false
        @State private var waitingRetryCount = 0
        @State private var showWaitingAlert = false
        @State private var showLockedAlert = false

    // MARK: - 팔레트 위에 있는지 판별 (삭제용)
    private func isOverPalette() -> Bool {
        dragManager.isDragging &&
        dragManager.dragSource == .canvas &&
        paletteFrame.contains(dragManager.dragPosition)
    }

    var body: some View {
        ZStack {

            // =================================================
            // 메인 콘텐츠
            // =================================================
            VStack(spacing: 0) {

                // 게임 맵
                if let subQuest = viewModel.subQuest {
                    GameMapView(
                        viewModel: viewModel,
                        questTitle: subQuest.title
                    )
                    .frame(height: 450)
                } else {
                    ProgressView("불러오는 중...")
                        .frame(height: 450)
                }

                // =================================================
                // 블록 영역
                // =================================================
                HStack(spacing: 0) {

                    // ---------- 팔레트 ----------
                    GeometryReader { geo in
                        ZStack {

                            // =================================================
                            // 🔥 삭제 오버레이 (팔레트 영역 전체, 여백 없음)
                            // =================================================
                            if isOverPalette() {
                                GeometryReader { geo in
                                    HStack(spacing: 0) {
                                        // 🔴 팔레트 영역만 붉게
                                        Color.red.opacity(0.35)
                                            .frame(width: 140)
                                            .overlay(
                                                VStack {
                                                    Spacer()
                                                    Text("삭제")
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                        .padding(.bottom, 40)
                                                }
                                            )

                                        // 나머지 영역은 투명
                                        Color.clear
                                    }
                                    .ignoresSafeArea()          // 🔥 하단 여백 제거 핵심
                                }
                                .zIndex(20)
                            }

                            BlockPaletteView()
                                .environmentObject(dragManager)
                                .environmentObject(viewModel)
                                .zIndex(2)
                        }
                        .background(Color.white)
                        .onAppear {
                            paletteFrame = geo.frame(in: .global)
                        }
                        .onChange(of: dragManager.dragPosition) { _ in
                            paletteFrame = geo.frame(in: .global)
                        }
                    }
                    .frame(width: 140)

                    // ---------- 캔버스 ----------
                    BlockCanvasView(
                        paletteFrame: $paletteFrame
                    )
                    .environmentObject(dragManager)
                    .environmentObject(viewModel)
                    .background(Color.gray.opacity(0.1))
                }
            }
            
            // =================================================
            // ⏳ Waiting Overlay
            // =================================================
            if isWaitingOverlay {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 10) {
                            ProgressView()
                            Text("다음 퀘스트 여는 중입니다…")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(18)
                        .background(Color.black.opacity(0.55))
                        .cornerRadius(14)
                    )
                    .zIndex(50)
            }

            // =================================================
            // 👻 고스트 블록 (일반 / 반복문 분기)
            // =================================================
            if dragManager.isDragging {

                // 반복문 고스트
                if let block = dragManager.draggingBlock,
                   block.type == .repeatCount {

                    GhostContainerBlockView(
                        block: block,
                        position: dragManager.dragPosition,
                    )
                    .ignoresSafeArea()
                    .zIndex(30)

                }
                // 일반 블록 고스트
                else if let type = dragManager.draggingType {

                    GhostBlockView(
                        type: type,
                        position: dragManager.dragPosition,
                        offset: dragManager.dragStartOffset
                    )
                    .ignoresSafeArea()
                    .zIndex(30)
                }
            }

            // =================================================
            // ❌ 실패 다이얼로그
            // =================================================
            if viewModel.showFailureDialog {
                FailureDialogView {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        viewModel.showFailureDialog = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        viewModel.resetExecution()
                    }
                }
                .zIndex(40)
            }

            // =================================================
            // ✅ 성공 다이얼로그
            // =================================================
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
                            waitingRetryCount = 0
                            isWaitingOverlay = true
                            tryGoNextHandlingWaiting()
                        }
                    }
                )
                .zIndex(40)
            }
        }
        .environmentObject(dragManager)
        .environmentObject(viewModel)

        // =================================================
        // 🔥 드래그 종료 처리 (유일한 진입점)
        // =================================================
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    dragManager.finishDrag(at: value.location) {
                        endPos, source, type, block in

                        guard !viewModel.isExecuting else { return }
                        
                        // 팔레트 > 반복문 내부
                        if source == .palette,
                           let type = type,
                           dragManager.isOverContainer,
                           let target = dragManager.containerTargetBlock {

                            target.children.append(Block(type: type))
                            return
                        }

                        // 1️⃣ 캔버스 → 팔레트 (삭제)
                        if source == .canvas,
                           let block = block,
                           paletteFrame.contains(endPos) {
                            
                            print("🧨 DELETE target:", block.type, block.id)
                            print("🧨 parent:", dragManager.draggingParentContainer?.id as Any)

                            // 🔥 반복문 내부 블록이면
                            if let parent = viewModel.findParentContainer(of: block) {
                                parent.children.removeAll { $0.id == block.id }
                            } else {
                                viewModel.startBlock.children.removeAll { $0.id == block.id }
                            }
                            return
                        }

                        // 2️⃣ 팔레트 → 캔버스 (추가)
                        if source == .palette,
                           let type = type,
                           dragManager.isOverCanvas {

                            let index = dragManager.canvasInsertIndex
                            ?? viewModel.startBlock.children.count
                            viewModel.startBlock.children.insert(Block(type: type), at: index)
                            return
                        }

                        // 3️⃣ 캔버스 → 캔버스 (재정렬)
                        if source == .canvas,
                           let block = block,
                           dragManager.isOverCanvas,
                           let fromIndex = viewModel.startBlock.children.firstIndex(where: { $0.id == block.id }) {

                            let index = dragManager.canvasInsertIndex
                            ?? viewModel.startBlock.children.count

                            if fromIndex == index || fromIndex + 1 == index { return }

                            viewModel.startBlock.children.remove(at: fromIndex)
                            let adjusted = fromIndex < index ? index - 1 : index
                            viewModel.startBlock.children.insert(block, at: adjusted)
                        }
                    }
                }
        )

        // 초기 로딩
        .onAppear {
            appState.isInGame = true
            tabBarViewModel.isTabBarVisible = false
            viewModel.fetchSubQuest(
                chapterId: chapterId,
                subQuestId: subQuestId
            )
        }

        // 네비게이션
        .navigationDestination(item: $goToNextQuestId) { nextId in
            QuestBlockView(chapterId: chapterId, subQuestId: nextId)
        }
        .navigationDestination(isPresented: $goBackToQuestList) {
            QuestListView()
        }
        
        // 알럿
        .alert("⏳ 챕터를 여는 중이에요", isPresented: $showWaitingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("서버 반영이 지연되고 있어요.\n잠시 후 다시 시도해 주세요.")
        }

        .alert("🔒 잠긴 퀘스트입니다", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("선행 퀘스트를 먼저 완료해 주세요.")
        }
        
        
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.all, edges: .top)
        
        
    }

    // MARK: - 다음 퀘스트 이동 (waiting 포함)
    private func tryGoNextHandlingWaiting() {
        isWaitingOverlay = true
        
        viewModel.goToNextSubQuest { action in
            DispatchQueue.main.async {
                switch action {
                // 다음 스테이지로 이동
                case .goToQuest(let nextId):
                    isWaitingOverlay = false
                    goToNextQuestId = nextId
                    
                // 리스트로 이동
                case .goToList:
                    isWaitingOverlay = false
                    appState.isInGame = false
                    goBackToQuestList = true

                case .waiting:
                    waitingRetryCount += 1
                    let maxRetry = 6
                    let delay: Double = 0.6

                    if waitingRetryCount <= maxRetry {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            tryGoNextHandlingWaiting()
                        }
                    } else {
                        isWaitingOverlay = false
                        showWaitingAlert = true
                    }

                case .locked:
                    isWaitingOverlay = false
                    showLockedAlert = true
                }
            }
        }
    }
}
