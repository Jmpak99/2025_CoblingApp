//
//  BlockCanvasView.swift
//  Cobling
//

import SwiftUI

struct DropIndicatorBar: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.green.opacity(0.6))
            .frame(height: 6)
            .padding(.vertical, 6)
    }
}

struct BlockCanvasView: View {
    @ObservedObject var startBlock: Block

    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel

    @Binding var paletteFrame: CGRect

    @State private var isDropTarget: Bool = false
    @State private var previousChildCount: Int = 0   // ✅ 이전 개수 저장

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {

                    // startBlock 하나만 렌더링
                    BlockView(block: startBlock)
                        .environmentObject(dragManager)
                        .environmentObject(viewModel)

                    // 🔥 Drop Indicator (UI 전용)
                    if dragManager.isDragging && isDropTarget {
                        DropIndicatorBar()
                            .transition(.opacity)
                    }

                    // ✅ 스크롤 타겟 앵커
                    Color.clear
                        .frame(height: 1)
                        .id("canvasBottom")
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .topLeading)

                // 캔버스 영역 판별
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: dragManager.dragPosition) { position in
                                let frame = geo.frame(in: .global)
                                isDropTarget = frame.contains(position)
                            }
                    }
                )
            }

            // ✅ 블록 "추가" 시에만 자동 스크롤
            .onChange(of: startBlock.children.count) { newCount in
                if newCount > previousChildCount {
                    withAnimation(.easeInOut(duration: 0.25)) {
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
}
