import SwiftUI

/// 드래그 중인 블록을 따라다니는 고스트 뷰
struct GhostBlockView: View {
    let type: BlockType
    let position: CGPoint
    let offset: CGSize

    var body: some View {
        Image(type.imageName)
            .resizable()
            .frame(width: 120, height: 30)
            .opacity(0.6)
            .shadow(radius: 4)
            .position(
                x: position.x - offset.width,
                y: position.y - offset.height
            )
            .allowsHitTesting(false) // 🔥 매우 중요
    }
}
