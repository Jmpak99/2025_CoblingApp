import SwiftUI

// MARK: - 드래그 출처
enum DragSource {
    case palette
    case canvas
}

// MARK: - DragManager (최종 안정 버전)
final class DragManager: ObservableObject {

    // =========================
    // 드래그 상태
    // =========================
    @Published var isDragging: Bool = false

    // =========================
    // 드래그 대상 정보
    // =========================
    @Published var draggingType: BlockType?
    @Published var draggingBlock: Block?

    /// 🔥 현재 드래그를 "소유"한 블록 ID
    /// (재귀 BlockView에서 고스트 2개 생성 방지용)
    @Published var draggingBlockID: UUID?

    @Published var dragSource: DragSource = .palette

    // =========================
    // 고스트 블록 위치 정보
    // =========================
    @Published var dragPosition: CGPoint = .zero
    @Published var dragStartOffset: CGSize = .zero

    // =========================
    // MARK: - 드래그 시작 준비 (최초 1회)
    // =========================
    func prepareDragging(
        type: BlockType,
        at position: CGPoint,
        offset: CGSize,
        block: Block? = nil,
        source: DragSource
    ) {
        // 이미 드래그 중이면 무시 (이중 시작 방지)
        guard isDragging == false else { return }

        draggingType = type
        draggingBlock = block
        draggingBlockID = block?.id
        dragSource = source

        dragPosition = position
        dragStartOffset = offset

        isDragging = true
    }

    // =========================
    // MARK: - 드래그 위치 업데이트 (계속 호출)
    // =========================
    func updateDragPosition(_ position: CGPoint) {
        guard isDragging else { return }
        dragPosition = position
    }

    // =========================
    // MARK: - 드래그 종료 (단 1회)
    // =========================
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

    // =========================
    // MARK: - 상태 초기화
    // =========================
    func reset() {
        isDragging = false

        draggingType = nil
        draggingBlock = nil
        draggingBlockID = nil
        dragSource = .palette

        dragPosition = .zero
        dragStartOffset = .zero
    }
}
