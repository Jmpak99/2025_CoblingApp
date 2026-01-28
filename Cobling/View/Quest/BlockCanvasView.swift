//
//  BlockCanvasView.swift
//  Cobling
//

import SwiftUI

// MARK: - Drop Indicator Bar
struct DropIndicatorBar: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.green.opacity(0.6))
            .frame(height: 6)
    }
}

// MARK: - Block Frame PreferenceKey
struct BlockFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(
        value: inout [UUID: CGRect],
        nextValue: () -> [UUID: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Block Canvas View
struct BlockCanvasView: View {
    
    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel

    @Binding var paletteFrame: CGRect
    
    @State private var canvasFrame: CGRect = .zero

    @State private var isDropTarget: Bool = false
    @State private var previousChildCount: Int = 0

    @State private var blockFrames: [UUID: CGRect] = [:]
    @State private var insertIndex: Int? = nil
    
    // ✅ StartBlock 하위 들여쓰기 값
    private let childIndent: CGFloat = 20
    private let childBlockWidth : CGFloat = 120

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Start Block
                    BlockView(block: viewModel.startBlock, parentContainer: nil)
                        .environmentObject(dragManager)
                        .environmentObject(viewModel)
                    
                    // 실행 블록
                    ForEach(Array(viewModel.startBlock.children.enumerated()), id: \.element.id) { index, block in
                        
                        // 중간 삽입 인디케이터
                        if dragManager.isDragging,
                           dragManager.containerTargetBlock == nil,
                            insertIndex == index {
                            
                            HStack(spacing: 0) {
                                Spacer().frame(width: childIndent)
                                
                                DropIndicatorBar()
                                    .frame(width: childBlockWidth)
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        
                        BlockView(block: block, parentContainer: nil)
                            .environmentObject(dragManager)
                            .environmentObject(viewModel)
                            .padding(.leading, childIndent)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: BlockFramePreferenceKey.self,
                                        value: [
                                            block.id: geo.frame(in: .named("canvas"))
                                        ]
                                    )
                                }
                            )
                    }
                    
                    // 마지막 위치 인디케이터
                    if dragManager.isDragging,
                       dragManager.containerTargetBlock == nil,
                        insertIndex == viewModel.startBlock.children.count {
                        
                        HStack(spacing: 0) {
                            Spacer().frame(width: childIndent)
                            
                            DropIndicatorBar()
                                .frame(width: childBlockWidth)
                            
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    
                    Color.clear
                        .frame(height: 1)
                        .id("canvasBottom")
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
                .padding(.leading, 10)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                .onPreferenceChange(BlockFramePreferenceKey.self) {
                    blockFrames = $0
                }
                
                // ⭐ 핵심 수정 부분
                // ✅ 캔버스 드롭 타겟 판정 + 삽입 인덱스 계산
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: dragManager.dragPosition) { globalPos in
                                let frame = geo.frame(in: .global)

                                guard dragManager.isDragging else {
                                    insertIndex = nil
                                    dragManager.canvasInsertIndex = nil
                                    return
                                }

                                // ✅ 컨테이너가 활성화된 상태면, 캔버스는 드롭 타겟이 되면 안 됨
                                if dragManager.containerTargetBlock != nil {
                                    dragManager.isOverCanvas = false
                                    insertIndex = nil
                                    dragManager.canvasInsertIndex = nil
                                    return
                                }

                                if frame.contains(globalPos) {
                                    dragManager.isOverCanvas = true

                                    // ✅ 삽입 위치 계산 (canvas 좌표계로 변환)
                                    let localY = globalPos.y - frame.minY
                                    let idx = calculateInsertIndex(dragY: localY)

                                    insertIndex = idx
                                    dragManager.canvasInsertIndex = idx
                                } else {
                                    dragManager.isOverCanvas = false
                                    insertIndex = nil
                                    dragManager.canvasInsertIndex = nil
                                }
                            }
                    }
                )
            }
            .coordinateSpace(name: "canvas")

            // 자동 스크롤
            .onChange(of: viewModel.startBlock.children.count) { newCount in
                if newCount > previousChildCount {
                    withAnimation {
                        proxy.scrollTo("canvasBottom", anchor: .bottom)
                    }
                }
                previousChildCount = newCount
            }
            .onAppear {
                previousChildCount = viewModel.startBlock.children.count
            }
        }
    }

    private func calculateInsertIndex(dragY: CGFloat) -> Int {
        for (index, block) in viewModel.startBlock.children.enumerated() {
            guard let frame = blockFrames[block.id] else { continue }
            if dragY < frame.midY {
                return index
            }
        }
        return viewModel.startBlock.children.count
    }
}
