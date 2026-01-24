import SwiftUI

// MARK: - 드래그 출처
enum DragSource {
    case palette
    case canvas
}

// MARK: - DragManager (최종 안정 버전)
final class DragManager: ObservableObject {
    @Published var isDragging: Bool = false
    @Published var draggingType: BlockType?
    @Published var draggingBlock: Block?
    @Published var draggingBlockID: UUID?
    @Published var dragSource: DragSource = .palette
    @Published var dragPosition: CGPoint = .zero
    @Published var dragStartOffset: CGSize = .zero

    // ✅ 캔버스 드롭 정보(캔버스가 계산해서 넣어줌)
    @Published var isOverCanvas: Bool = false
    @Published var canvasInsertIndex: Int? = nil
    
    @Published var isOverContainer: Bool = false
    @Published var containerTargetBlock: Block? = nil
    
    @Published var containerInsertIndex: Int? = nil
    
    @Published var draggingParentContainer: Block? = nil

    func prepareDragging(
        type: BlockType,
        at position: CGPoint,
        offset: CGSize,
        block: Block? = nil,
        parentContainer : Block? = nil,
        source: DragSource
    ) {
        guard isDragging == false else { return }

        draggingType = type
        draggingBlock = block
        draggingBlockID = block?.id
        draggingParentContainer = parentContainer
        dragSource = source

        dragPosition = position
        dragStartOffset = offset

        isDragging = true
    }

    func updateDragPosition(_ position: CGPoint) {
        guard isDragging else { return }
        dragPosition = position
    }

    func finishDrag(
        at position: CGPoint,
        onFinish: (
            _ endPosition: CGPoint,
            _ source: DragSource,
            _ type: BlockType?,
            _ block: Block?
        ) -> Void
    ) {
        guard isDragging else { return }
        onFinish(position, dragSource, draggingType, draggingBlock)
        reset()
    }

    func reset() {
        isDragging = false
        draggingType = nil
        draggingBlock = nil
        draggingBlockID = nil
        draggingParentContainer = nil
        dragSource = .palette
        dragPosition = .zero
        dragStartOffset = .zero

        // ✅ 캔버스 상태도 리셋
        isOverCanvas = false
        canvasInsertIndex = nil
        
        isOverContainer = false
        containerTargetBlock = nil
        containerInsertIndex = nil
    }
}
