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
    @ObservedObject var startBlock: Block

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
                    BlockView(block: startBlock)
                        .environmentObject(dragManager)
                        .environmentObject(viewModel)

                    // 실행 블록
                    ForEach(Array(startBlock.children.enumerated()), id: \.element.id) { index, block in
                        
                        // 중간 삽입 인디케이터
                        if dragManager.isDragging && insertIndex == index {
                            HStack(spacing: 0) {
                                Spacer().frame(width: childIndent)

                                DropIndicatorBar()
                                    .frame(width: childBlockWidth)

                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }

                        BlockView(block: block)
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

                    if dragManager.isDragging &&
                        insertIndex == startBlock.children.count {

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
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                .onPreferenceChange(BlockFramePreferenceKey.self) {
                    blockFrames = $0
                }

                // ⭐ 핵심 수정 부분
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: dragManager.dragPosition) { globalPos in

                                let currentCanvasFrame = geo.frame(in: .global)
                                canvasFrame = currentCanvasFrame   // 🔥 항상 최신값

                                let over = currentCanvasFrame.contains(globalPos)
                                isDropTarget = over

                                if over && dragManager.isDragging {
                                    let localY = globalPos.y - currentCanvasFrame.minY
                                    let idx = calculateInsertIndex(dragY: localY)

                                    insertIndex = idx
                                    dragManager.isOverCanvas = true
                                    dragManager.canvasInsertIndex = idx
                                } else {
                                    insertIndex = nil
                                    dragManager.isOverCanvas = false
                                    dragManager.canvasInsertIndex = nil
                                }
                            }
                    }
                )
            }
            .coordinateSpace(name: "canvas")

            // 자동 스크롤
            .onChange(of: startBlock.children.count) { newCount in
                if newCount > previousChildCount {
                    withAnimation {
                        proxy.scrollTo("canvasBottom", anchor: .bottom)
                    }
                }
                previousChildCount = newCount
            }
            .onAppear {
                previousChildCount = startBlock.children.count
            }
        }
    }

    private func calculateInsertIndex(dragY: CGFloat) -> Int {
        for (index, block) in startBlock.children.enumerated() {
            guard let frame = blockFrames[block.id] else { continue }
            if dragY < frame.midY {
                return index
            }
        }
        return startBlock.children.count
    }
}
