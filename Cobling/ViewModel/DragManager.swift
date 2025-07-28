import Foundation
import SwiftUI

/// 전역 드래그 상태를 관리하는 ObservableObject
class DragManager: ObservableObject {
    @Published var isDragging: Bool = false
    @Published var draggingType: BlockType? = nil
    @Published var dragPosition: CGPoint = .zero
    @Published var dragStartOffset: CGSize = .zero
    
    func prepareDragging(type: BlockType, at position: CGPoint, offset: CGSize) {
        // 위치는 먼저 설정하지만 isDragging은 아직 false
        self.draggingType = type
        self.dragStartOffset = offset
        self.dragPosition = position
    }


    func startDragging() {
        self.isDragging = true
    }

    func updatePosition(to position: CGPoint) {
        self.dragPosition = position
    }

    func endDragging() {
        self.isDragging = false
        self.draggingType = nil
        self.dragPosition = .zero
        self.dragStartOffset = .zero
    }
}
