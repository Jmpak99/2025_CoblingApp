//
//  BlockCanvasView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//

import SwiftUI

/// 우측 조립 영역 - 시작 블록과 붙는 블록을 나열
struct BlockCanvasView: View {
    @ObservedObject var startBlock: Block
    var onDropBlock: (BlockType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // 시작 블록 + 자식 블록들 표시
            BlockView(block: startBlock)
        }
        .padding()
        .frame(maxWidth: .infinity,maxHeight: .infinity ,alignment: .topLeading)
        .background(Color(hex: "#F2F2F2"))
        .onDrop(of: [.text], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - 드롭된 블록 타입을 처리
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        if let provider = providers.first {
            provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
                guard let data = item as? Data,
                      let typeString = String(data: data, encoding: .utf8),
                      let blockType = BlockType(rawValue: typeString) else {
                    return
                }

                DispatchQueue.main.async {
                    // 새로운 블록을 시작 블록의 자식으로 추가
                    let newBlock = Block(type: blockType)
                    startBlock.children.append(newBlock)
                    onDropBlock(blockType)
                }
            }
            return true
        }
        return false
    }
}

// MARK: - 미리보기
#if DEBUG
struct BlockCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        let start = Block(type: .start)
        return BlockCanvasView(startBlock: start) { type in
            print("드롭한 블록 타입: \(type)")
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 300, height: 300)
    }
}
#endif
