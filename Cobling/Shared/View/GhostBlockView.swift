import SwiftUI

/// 드래그 중인 블록을 따라다니는 고스트 뷰
struct GhostBlockView: View {
    let type: BlockType
    let position: CGPoint
    let offset: CGSize

    init(type: BlockType, position: CGPoint, offset: CGSize) {
        self.type = type
        self.position = position
        self.offset = offset

        // ✅ 여기에서 안전하게 로그 출력 가능
        print("📍 고스트블록 위치:", position)
    }

    
    var body: some View {
        
        if position == .zero {
            // 위치가 없으면 표시하지 않음
            EmptyView()
        } else {
            Image(type.imageName)
                .resizable()
                .frame(width: 120, height: 30)
                .opacity(0.7)
                .shadow(radius: 4)
                .position(x: position.x - offset.width, y: position.y - offset.height)
        }
    }
}
