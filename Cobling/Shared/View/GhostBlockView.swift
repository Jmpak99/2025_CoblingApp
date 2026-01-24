import SwiftUI

/// 드래그 중인 블록을 따라다니는 고스트 뷰
struct GhostBlockView: View {
    let type: BlockType
    let position: CGPoint
    let offset: CGSize

    var body: some View {
        Image(type.imageName)
            .resizable()
            .frame(
                width: ghostSize.width,
                height: ghostSize.height
            )
            .opacity(0.6)
            .shadow(radius: 4)
            .position(
                x: position.x - offset.width,
                y: position.y - offset.height
            )
            .allowsHitTesting(false) // 🔥 필수
    }

    // MARK: - 고스트 크기 분기
    private var ghostSize: CGSize {
        switch type {
        case .repeatCount:
            return CGSize(width: 165, height: 36)
        case .start:
            return CGSize(width: 160, height: 50)
        default:
            return CGSize(width: 120, height: 30)
        }
    }
}
