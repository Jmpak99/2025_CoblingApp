import Foundation
import Foundation
import SwiftUI

// MARK: - 드래그 출처 구분
enum DragSource {
    case palette
    case canvas
}

// MARK: - 드래그 상태를 관리하는 매니저
class DragManager: ObservableObject {
    @Published var isDragging = false                    // 현재 드래그 중인지 여부
    @Published var draggingType: BlockType?              // 드래그 중인 블록 타입
    @Published var draggingBlock: Block?                 // 드래그 중인 실제 Block 객체 (캔버스에서 드래그 시)
    @Published var dragPosition: CGPoint = .zero         // 현재 드래그 위치
    @Published var dragStartOffset: CGSize = .zero       // 시작 시 오프셋
    @Published var dragEndedAt: CGPoint? = nil           // 드래그가 끝난 위치
    @Published var dragSource: DragSource = .palette     // 드래그가 시작된 위치

    /// 드래그 준비
    func prepareDragging(
        type: BlockType,
        at position: CGPoint,
        offset: CGSize, 
        block: Block? = nil,
        source: DragSource = .palette
    ) {
        draggingType = type
        draggingBlock = block
        dragPosition = position
        dragStartOffset = offset
        dragSource = source
    }

    /// 드래그 시작
    func startDragging() {
        isDragging = true
    }

    /// 드래그 위치 업데이트
    func updateDragPosition(_ position: CGPoint) {
        dragPosition = position
    }

    /// 드래그 종료
    func endDragging(at position: CGPoint) {
        dragEndedAt = position
        isDragging = false
    }

    /// 상태 초기화
    func reset() {
        isDragging = false
        draggingType = nil
        draggingBlock = nil
        dragPosition = .zero
        dragStartOffset = .zero
        dragEndedAt = nil
        dragSource = .palette
    }
}

