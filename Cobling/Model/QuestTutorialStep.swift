//
//  QuestTutorialStep.swift
//  Cobling
//
//  Created by 박종민 on 3/6/26.
//

import Foundation

/// 1-1 퀘스트 진입 시 보여줄 설명형 튜토리얼 단계
/// - 사용자는 각 단계를 [다음] 버튼으로 순차적으로 넘깁니다.
/// - 모든 안내를 본 뒤 실제 게임을 처음 상태에서 시작합니다.
enum QuestTutorialStep: Int, CaseIterable, Identifiable {
    case storyIntro          // 1. 스토리 소개
    case explainStoryButton  // 2. 스토리 버튼 소개
    case explainBlockPalette // 3. 왼쪽 블록 설명
    case explainPlaceBlock   // 4. 블록 배치 설명
    case explainPlayButton   // 5. 시작 버튼 설명
    case explainStopButton   // 6. 멈춤 버튼 설명
    case explainReachFlag    // 7. 깃발 도착 설명
    case readyToStart        // 8. 이제 직접 시작하기
    case completed           // 9. 종료

    var id: Int { rawValue }
}

// MARK: - UI Data
extension QuestTutorialStep {

    /// 현재 단계 제목
    var title: String {
        switch self {
        case .storyIntro:
            return "스토리 소개"
        case .explainStoryButton:
            return "스토리 버튼"
        case .explainBlockPalette:
            return "블록 사용하기"
        case .explainPlaceBlock:
            return "블록 배치하기"
        case .explainPlayButton:
            return "시작 버튼"
        case .explainStopButton:
            return "멈춤 버튼"
        case .explainReachFlag:
            return "성공 조건"
        case .readyToStart:
            return "직접 시작하기"
        case .completed:
            return "튜토리얼 종료"
        }
    }

    /// 현재 단계 설명 문구
    var message: String {
        switch self {
        case .storyIntro:
            return "코블링이 깨어나기 위해서는 도움이 필요해요. \n먼저 게임 화면에서 어떤 기능을 사용할지 같이 알아볼까요?"
        case .explainStoryButton:
            return "스토리 버튼을 누르면 현재 퀘스트의 스토리와 설명을 다시 확인할 수 있어요."
        case .explainBlockPalette:
            return "왼쪽에는 코블링을 움직일 수 있는 블록들이 있어요. 필요한 블록을 골라 사용할 수 있어요."
        case .explainPlaceBlock:
            return "블록을 드래그해서 시작 블록 아래에 순서대로 배치하면 코블링의 행동이 만들어져요."
        case .explainPlayButton:
            return "블록 배치가 끝나면 시작 버튼을 눌러 코블링을 움직일 수 있어요."
        case .explainStopButton:
            return "실행 중에는 멈춤 버튼을 눌러 언제든지 중지할 수 있어요."
        case .explainReachFlag:
            return "코블링이 깃발에 도착하면 퀘스트 성공이에요!"
        case .readyToStart:
            return "이제 게임 방법을 모두 확인했어요. \n직접 블록을 배치해서 코블링을 움직여볼까요?"
        case .completed:
            return "튜토리얼이 종료되었어요."
        }
    }

    /// 현재 단계에서 강조할 UI 대상
    var focusTarget: QuestTutorialFocusTarget? {
        switch self {
        case .storyIntro:
            return nil
        case .explainStoryButton:
            return .storyButton
        case .explainBlockPalette:
            return .blockPalette
        case .explainPlaceBlock:
            return .blockCanvas
        case .explainPlayButton:
            return .playButton
        case .explainStopButton:
            return .stopButton
        case .explainReachFlag:
            return .flag
        case .readyToStart:
            return nil
        case .completed:
            return nil
        }
    }

    /// 현재 단계에서 보여줄 기본 버튼 제목
    var primaryButtonTitle: String {
        switch self {
        case .readyToStart:
            return "시작하기"
        case .completed:
            return "확인"
        default:
            return "다음"
        }
    }

    /// 현재 단계에서 보조 버튼(건너뛰기) 표시 여부
    var showsSkipButton: Bool {
        switch self {
        case .completed:
            return false
        default:
            return true
        }
    }

    /// 현재 단계가 실제 시작 직전 단계인지
    var isReadyToStartStep: Bool {
        self == .readyToStart
    }

    /// 현재 단계가 완료 단계인지
    var isCompletedStep: Bool {
        self == .completed
    }

    /// 진행 표시용 현재 단계 번호 (1부터 시작)
    /// completed는 표시 대상에서 제외하기 위해 nil 처리
    var visibleStepNumber: Int? {
        switch self {
        case .storyIntro:
            return 1
        case .explainStoryButton:
            return 2
        case .explainBlockPalette:
            return 3
        case .explainPlaceBlock:
            return 4
        case .explainPlayButton:
            return 5
        case .explainStopButton:
            return 6
        case .explainReachFlag:
            return 7
        case .readyToStart:
            return 8
        case .completed:
            return nil
        }
    }

    /// 진행 표시용 전체 단계 수
    var totalVisibleSteps: Int {
        8
    }
}

// MARK: - Step Navigation
extension QuestTutorialStep {

    /// 다음 단계
    var nextStep: QuestTutorialStep? {
        switch self {
        case .storyIntro:
            return .explainStoryButton
        case .explainStoryButton:
            return .explainBlockPalette
        case .explainBlockPalette:
            return .explainPlaceBlock
        case .explainPlaceBlock:
            return .explainPlayButton
        case .explainPlayButton:
            return .explainStopButton
        case .explainStopButton:
            return .explainReachFlag
        case .explainReachFlag:
            return .readyToStart
        case .readyToStart:
            return .completed
        case .completed:
            return nil
        }
    }

    /// 이전 단계
    var previousStep: QuestTutorialStep? {
        switch self {
        case .storyIntro:
            return nil
        case .explainStoryButton:
            return .storyIntro
        case .explainBlockPalette:
            return .explainStoryButton
        case .explainPlaceBlock:
            return .explainBlockPalette
        case .explainPlayButton:
            return .explainPlaceBlock
        case .explainStopButton:
            return .explainPlayButton
        case .explainReachFlag:
            return .explainStopButton
        case .readyToStart:
            return .explainReachFlag
        case .completed:
            return .readyToStart
        }
    }
}

// MARK: - Focus Target
enum QuestTutorialFocusTarget {
    case storyButton
    case blockPalette
    case blockCanvas
    case playButton
    case stopButton
    case flag
}
