//
//  BlockView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//

import SwiftUI

/// 단일 블록을 표시하는 뷰 - 드래그 가능, 자식 블록이 있다면 재귀 렌더링
struct BlockView: View {
    @ObservedObject var block: Block
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // MARK: - 블록 이미지 + 텍스트 오버레이
            Image(block.type.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: blockSize.width, height: blockSize.height)
                .overlay(
                    Group {
                        if let value = block.value, !value.isEmpty {
                            Text(value)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                        }
                    },
                    alignment: .trailing
                )
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .opacity(isDragging ? 0.8 : 1.0)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                            isDragging = true
                        }
                        .onEnded { _ in
                            isDragging = false
                            dragOffset = .zero
                        }
                )

            // MARK: - 자식 블록이 있는 경우 재귀 렌더링
            if block.type.isContainer && !block.children.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(block.children) { child in
                        BlockView(block: child)
                    }
                }
                .padding(.leading, 20)
            }
        }
        .padding(4)
        .background(Color.clear)
    }

    // MARK: - 블록 크기 설정 (시작 블록만 크게)
    private var blockSize: CGSize {
        switch block.type {
        case .start:
            return CGSize(width: 160, height: 60)
        default:
            return CGSize(width: 120, height: 30)
        }
    }
}


// MARK: - 미리보기 Preview
#if DEBUG
struct BlockView_Previews: PreviewProvider {
    static var previews: some View {
        let start = Block(type: .start)
        start.children = [
            Block(type: .moveForward),
            Block(type: .turnLeft)
        ]

        return BlockView(block: start)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.white)
    }
}
#endif
