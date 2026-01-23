//
//  BlockView.swift
//  Cobling
//

import SwiftUI

import SwiftUI

struct BlockView: View {
    @ObservedObject var block: Block
    
    let parentContainer: Block?

    @EnvironmentObject var dragManager: DragManager
    @EnvironmentObject var viewModel: QuestViewModel

    var body: some View {
        Group {
            if block.type.isContainer {
                // 🔁 반복문 / if / ifElse
                ContainerBlockView(block: block)
            } else {
                // ▶️ 이동 / 회전 / 공격 / 시작
                NormalBlockView(block: block, parentContainer: parentContainer)
            }
        }
        .environmentObject(dragManager)
        .environmentObject(viewModel)
    }
}
