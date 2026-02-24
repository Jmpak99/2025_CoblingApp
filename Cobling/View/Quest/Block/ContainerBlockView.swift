//
//  ContainerBlockView.swift
//  Cobling
//
//  Created by 박종민 on 1/23/26.
//

import SwiftUI

// 반복문 내부 블록 프레임 수집용 PreferenceKey
struct ContainerBlockFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(
        value: inout [UUID: CGRect],
        nextValue: () -> [UUID: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct ContainerBlockView: View {
    @ObservedObject var block: Block

    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel
    
    @State private var blockFrames: [UUID: CGRect] = [:]
    @State private var insertIndex: Int? = nil

    private let blockWidth: CGFloat = 165
    private let leftBarWidth: CGFloat = 12
    
    // MARK: - 실행 중인 반복문인지 판별
    private var isExecutingThisContainer: Bool {
        viewModel.currentExecutingBlockID == block.id
    }
    
    // MARK: - NormalBlockView와 동일한 opacity 규칙
    private var containerContentOpacity: Double {
        if viewModel.isExecuting && !isExecutingThisContainer {
            return 0.3
        }
        return 1.0
    }
    
    // 컨테이너 타입에 따라 색상 분기 (repeat / if / ifElse)
    private var containerTint: Color {
        switch block.type {
        case .repeatCount, .repeatForever:
            return Color(hex: "#86B0FF")      // repeat 계열
        case .if, .ifElse:
            return Color(hex: "#4CCB7A")      // if 계열
        default:
            return Color(hex: "#86B0FF")
        }
    }
    
    // 컨테이너 타입에 따라 빈 안내문구 분기
    private var emptyGuideText: String {
        switch block.type {
        case .repeatCount, .repeatForever:
            return "여기에 블록을 넣어주세요"
        case .if:
            return "조건이 맞으면 실행할 블록을 넣어주세요"
        case .ifElse:
            return "조건이 맞으면 실행할 블록을 넣어주세요" // (추후 else 영역 추가 시 문구 분리 가능)
        default:
            return "여기에 블록을 넣어주세요"
        }
    }
    
    // 컨테이너 타입에 따라 헤더 뷰 분기 (RepeatHeaderView / IfHeaderView)
    @ViewBuilder
    private var containerHeaderView: some View {
        switch block.type {
        case .repeatCount, .repeatForever:
            RepeatHeaderView(block: block)
        case .if, .ifElse:
            // 스테이지별 허용 조건/기본 조건을 ViewModel에서 주입
            IfHeaderView(
                block: block,
                options: viewModel.currentAllowedIfConditions,
                defaultCondition: viewModel.currentDefaultIfCondition
            )        // IfHeaderView가 프로젝트에 있어야 함
        default:
            RepeatHeaderView(block: block)
        }
    }
    

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // =========================
            // 왼쪽 세로 바
            // =========================
            Rectangle()
                .fill(containerTint)
                .frame(width: leftBarWidth)
                .clipShape(RoundedCorner(radius: 12, corners: [.topLeft, .bottomLeft]))

            VStack(alignment: .leading, spacing: 6) {

                // =========================
                // 반복문 헤더
                // =========================
                GeometryReader { geo in
                    containerHeaderView
                        .frame(width: blockWidth, height: 36)
                        .scaleEffect(isExecutingThisContainer ? 1.05 : 1.0)
                        .opacity(containerContentOpacity)
                        .animation(.easeInOut(duration: 0.15), value: isExecutingThisContainer)
                        .background(
                            containerTint
                                .clipShape(
                                    RoundedCorner(
                                        radius: 18,
                                        corners: [.topRight, .bottomRight]
                                    )
                                )
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if let ownerID = dragManager.draggingBlockID,
                                       ownerID != block.id {
                                        return
                                    }

                                    // global 좌표 변환
                                    let frame = geo.frame(in: .global)
                                    let position = CGPoint(
                                        x: frame.origin.x + value.location.x,
                                        y: frame.origin.y + value.location.y
                                    )

                                    if !dragManager.isDragging {
                                        dragManager.prepareDragging(
                                            type: block.type,
                                            at: position,
                                            offset: value.translation,
                                            block: block,
                                            parentContainer: viewModel.findParentContainer(of: block),
                                            source: .canvas
                                        )
                                    }

                                    dragManager.updateDragPosition(position)
                                }
                                .onEnded { value in
                                    let frame = geo.frame(in: .global)
                                    let position = CGPoint(
                                        x: frame.origin.x + value.location.x,
                                        y: frame.origin.y + value.location.y
                                    )

                                    dragManager.finishDrag(at: position) { _, _, _, _ in }
                                }
                        )
                }
                .frame(width: blockWidth, height: 36) // GeometryReader 크기 고정

                // =========================
                // 반복문 내부 영역
                // =========================
                VStack(alignment: .leading, spacing: 6) {
                    
                    // 블록이 하나도 없을 때
                    
                    if block.children.isEmpty {
                        Text(emptyGuideText)
                            .font(.pretendardBold14)
                            .foregroundColor(containerTint.opacity(0.35))
                            .padding(.vertical, 4)
                    }

                    // ─────────────
                    // 블록이 있을 때
                    // ─────────────
                    ForEach(Array(block.children.enumerated()), id: \.element.id) { index, child in

                        // ⭐ 중간 삽입 인디케이터
                        if dragManager.isDragging,
                           dragManager.containerTargetBlock?.id == block.id,
                           insertIndex == index {

                            DropIndicatorBar()
                                .frame(width: 120)
                                .padding(.leading, 6)
                                .padding(.vertical, 4)
                        }

                        // 실제 블록
                        BlockView(block: child, parentContainer : block)
                            .environmentObject(dragManager)
                            .environmentObject(viewModel)

                            // ⭐ 블록 frame 수집
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: ContainerBlockFrameKey.self,
                                        value: [
                                            child.id :
                                                geo.frame(in: .named("container"))
                                        ]
                                    )
                                }
                            )
                    }

                    // 마지막 위치 인디케이터
                    if dragManager.isDragging,
                       dragManager.containerTargetBlock?.id == block.id,
                       insertIndex == block.children.count {

                        DropIndicatorBar()
                            .frame(width: 120)
                            .padding(.leading, 6)
                            .padding(.vertical, 4)
                    }
                }
                .padding(.leading, 6)

                // =========================
                // 하단 캡
                // =========================
                Rectangle()
                    .fill(containerTint)
                    .frame(width: 100, height: 12)
                    .clipShape(
                        RoundedCorner(
                            radius: 6,
                            corners: [.topRight, .bottomRight]
                        )
                    )
            }
        }
        // 반복문 자체 드롭 타겟 판정
        .background(
            GeometryReader { geo in
                Color.clear
                    .onChange(of: dragManager.dragPosition) { globalPos in
                        let frame = geo.frame(in: .global)
                        
                        guard dragManager.isDragging else { return }

                        if frame.contains(globalPos) {

                                // 기존 타겟이 없으면 바로 설정
                                if dragManager.containerTargetBlock == nil {
                                    dragManager.containerTargetBlock = block
                                    dragManager.isOverContainer = true
                                    dragManager.isOverCanvas = false
                                    return
                                }

                                // 기존 타겟이 있는데,
                                // 내가 더 안쪽(자식) 컨테이너라면 교체 허용
                                if let current = dragManager.containerTargetBlock,
                                   viewModel.isDescendant(block, of: current) {

                                    dragManager.containerTargetBlock = block
                                    dragManager.isOverContainer = true
                                    dragManager.isOverCanvas = false
                                }

                        } else if dragManager.containerTargetBlock?.id == block.id {
                            // ❗️다른 더 안쪽 컨테이너가 없을 때만 해제
                            if dragManager.isOverContainer {
                                dragManager.containerTargetBlock = nil
                                dragManager.isOverContainer = false
                                dragManager.isOverCanvas = true
                            }
                        }
                    }
            }
        )

        // =========================
        // ⭐ 반복문 내부 frame 변화 반영
        // =========================
        .onPreferenceChange(ContainerBlockFrameKey.self) {
            blockFrames = $0
        }

        // =========================
        // ⭐ 드래그 위치 → 삽입 인덱스 계산
        // =========================
        .background(
            GeometryReader { geo in
                Color.clear
                    .onChange(of: dragManager.dragPosition) { globalPos in
                        let frame = geo.frame(in: .global)

                        guard frame.contains(globalPos),
                              dragManager.isDragging,
                              dragManager.containerTargetBlock?.id == block.id else {

                            insertIndex = nil
                            dragManager.containerInsertIndex = nil
                            return
                        }


                        let localY = globalPos.y - frame.minY
                        let idx = calculateInsertIndex(dragY: localY)

                        insertIndex = idx
                        dragManager.containerInsertIndex = idx
                    }
            }
        )
        .coordinateSpace(name: "container")
        .padding(.bottom, 2)
    }
    
    // MARK: - Container전용 DragGesture(중첩 대응 버전)
    private var containerDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if let ownerID = dragManager.draggingBlockID,
                   ownerID != block.id {
                    return
                }

                let position = value.location

                if !dragManager.isDragging {
                    dragManager.prepareDragging(
                        type: block.type,                 // repeat
                        at: position,
                        offset: value.translation,
                        block: block,
                        parentContainer: viewModel
                            .findParentContainer(of: block), // ⭐ 핵심
                        source: .canvas
                    )
                }

                dragManager.updateDragPosition(position)
            }
            .onEnded { value in
                dragManager.finishDrag(at: value.location) { _, _, _, _ in }
            }
    }

    // MARK: - 반복문 내부 삽입 위치 계산
    private func calculateInsertIndex(dragY: CGFloat) -> Int {
        for (index, child) in block.children.enumerated() {
            guard let frame = blockFrames[child.id] else { continue }
            if dragY < frame.midY {
                return index
            }
        }
        return block.children.count
    }
}


// MARK: - RoundedCorner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

