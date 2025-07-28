import Foundation
import SwiftUI

class DragManager: ObservableObject {
    @Published var isDragging = false
    @Published var draggingType: BlockType?
    @Published var dragPosition: CGPoint = .zero
    @Published var dragStartOffset: CGSize = .zero
    var dragEndedAt: CGPoint?

    func prepareDragging(type: BlockType, at position: CGPoint, offset: CGSize) {
        draggingType = type
        dragPosition = position
        dragStartOffset = offset
    }

    func startDragging() {
        isDragging = true
    }

    func updateDragPosition(_ position: CGPoint) {
        dragPosition = position
    }

    func endDragging(at position: CGPoint) {
        dragEndedAt = position
        isDragging = false
    }

    func reset() {
        draggingType = nil
        dragPosition = .zero
        dragStartOffset = .zero
        dragEndedAt = nil
    }
}
