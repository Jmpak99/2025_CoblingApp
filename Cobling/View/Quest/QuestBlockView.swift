import SwiftUI

struct QuestBlockView: View {
    let subQuest: SubQuest // 현재 퀘스트 정보
    @EnvironmentObject var tabBarViewModel: TabBarViewModel // 하단 탭바 상태 제어하는 뷰모델
    @StateObject private var dragManager = DragManager() // 드래그 상태 관리 객체
    @StateObject private var viewModel = QuestViewModel() // 퀘스트 상태 관리 뷰모델
    @StateObject private var startBlock = Block(type: .start) // 시작 블록(루트 블록)
    @State private var paletteFrame: CGRect = .zero // 블록 팔레트의 좌표 프레임

    // 팔레트 위에 드래그 중인지 여부
    private func isOverPalette() -> Bool {
        paletteFrame.contains(dragManager.dragPosition) // 드래그 위치가 팔래트 내부이고
            && dragManager.isDragging // 드래그 중이며
            && dragManager.dragSource == .canvas // 블록 출처가 캔버스인 경우
    }

    var body: some View {
        ZStack {
            mainContent() // 메인 UI 구성
            
            // 실패 다이얼로그가 표시되어야 할 때
            if viewModel.showFailureDialog {
                FailureDialogView {
                    // 애니메이션으로 닫고 이후 상태 초기화
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
            
            // 성공 다이얼로그가 표시되어야 할 때
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
            tabBarViewModel.isTabBarVisible = false // 진입 시 탭바 숨김
        }
        
        .onDisappear {
            tabBarViewModel.isTabBarVisible = true // 나갈 때 탭바 다시 표시
        }
        
        .onChange(of: startBlock.children) { newChildren in
            // startBlock 자식이 바뀌면 viewModel의 startBlock에도 반영
            viewModel.startBlock.children = newChildren
        }
        .animation(.easeInOut, value: viewModel.showFailureDialog || viewModel.showSuccessDialog) // 다이얼로그 애니메이션
        .navigationBarBackButtonHidden(true) // 백버튼 지우기
        .ignoresSafeArea(.all, edges: .top) // 상단 여백(Safe area) 제거
    }

    // MARK: - 메인 콘텐츠 뷰 구성
    @ViewBuilder
    private func mainContent() -> some View {
        VStack(spacing: 0) {
            // 게임 맵 뷰 (상단 고정)
            GameMapView(viewModel: viewModel, questTitle: subQuest.title)
                .frame(height: 500)
            
            ZStack {
                HStack(spacing: 0) {
                    paletteColumn() // 왼쪽 블록 팔레트
                    
                    // 블록 캔버스 뷰
                    BlockCanvasView(
                        startBlock: startBlock, // 시작 블록 전달
                        onDropBlock: { droppedType in
                            // 드롭 시 새로운 블록 추가
                            let newBlock = Block(type: droppedType)
                            startBlock.children.append(newBlock)
                        },
                        onRemoveBlock: { removedBlock in
                            // 삭제 시 자식 목록에서 제거
                            startBlock.children.removeAll { $0.id == removedBlock.id }
                        },
                        paletteFrame: $paletteFrame // 팔레트 프레임 바인딩 전달
                    )
                    .background(Color.gray.opacity(0.1)) // 캔버스 배경
                    .environmentObject(dragManager) // 드래그 매니저 전달
                }
                .coordinateSpace(name: "global") // 좌표 기준 설정
                ghostBlockViewIfNeeded() // 드래그 중 고스트 블록 표시
            }
            .environmentObject(dragManager)
        }
    }

    // MARK: - 블록 팔레트 컬럼
    @ViewBuilder
    private func paletteColumn() -> some View {
        GeometryReader { geo in
            ZStack {
                // 드래그된 블록이 팔레트 위에 있을 때 빨간 배경으로 "삭제"
                if isOverPalette() {
                    Color.red.opacity(0.3)
                        .overlay(
                            Text("삭제")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                        .ignoresSafeArea(.all, edges: .bottom)
                } else {
                    // 기본 배경은 흰색
                    Color.white
                }
                
                // 블록 팔레트 뷰
                BlockPaletteView()
                    .environmentObject(dragManager)
            }
            .onAppear {
                // 팔레트 프레임 좌표값 초기화
                paletteFrame = geo.frame(in: .named("global"))
            }
            .onChange(of: dragManager.dragPosition) { _ in
                // 드래그 위치 변경 시 팔레트 좌표 갱신
                paletteFrame = geo.frame(in: .named("global"))
            }
        }
        .frame(width: 200) // 팔레트 너비 지정
    }

    // MARK: - 고스트 블록 표시
    @ViewBuilder
    private func ghostBlockViewIfNeeded() -> some View {
        if dragManager.isDragging, // 드래그 중이고
           let type = dragManager.draggingType, // 드래그 중인 블록 타입이 존재하며
           dragManager.dragSource == .palette { // 출처가 팔레트 일 경우에만 고스트 표시
            GhostBlockView(
                type: type, // 블록 타입
                position: dragManager.dragPosition, // 현재 드래그 위치
                offset: dragManager.dragStartOffset // 시작 지점 대비 오프셋
            )
        }
    }
}

// MARK: - 미리보기
#if DEBUG
struct QuestBlockView_Previews: PreviewProvider {
    static var previews: some View {
        QuestBlockView(subQuest: SubQuest(
            title: "1. 알 속의 꿈틀",
            description: "무언가 꿈틀거려요.",
            state: .inProgress
        ))
        .environmentObject(TabBarViewModel()) // 미리보기용 탭바 뷰 모델 주입
        .previewLayout(.device) // 기기 화면에 맞춰 미리보기
        .previewDisplayName("퀘스트 블록 뷰 미리보기") // 미리보기 이름 지정
        .frame(width: 430, height: 932) // 아이폰 14 프로맥스 크기
    }
}
#endif

