//
//  QuestTutorialViewModel.swift
//  Cobling
//
//  Created by 박종민 on 3/6/26.
//

import Foundation
import SwiftUI

@MainActor
final class QuestTutorialViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 튜토리얼 오버레이가 현재 활성화되어 있는지 여부
    @Published var isActive: Bool = false

    /// 현재 표시 중인 튜토리얼 단계
    @Published var currentStep: QuestTutorialStep = .storyIntro

    /// 튜토리얼이 완전히 종료되었는지 여부
    @Published var isFinished: Bool = false

    /// 사용자가 튜토리얼을 건너뛰었는지 여부
    @Published var isSkipped: Bool = false

    // MARK: - Private Properties

    /// 튜토리얼 식별 키
    /// 예: "tutorial.quest.ch1.sq1"
    private(set) var tutorialKey: String?

    // MARK: - Computed Properties

    /// 현재 단계 제목
    var title: String {
        currentStep.title
    }

    /// 현재 단계 설명 문구
    var message: String {
        currentStep.message
    }

    /// 현재 단계의 강조 대상
    var focusTarget: QuestTutorialFocusTarget? {
        currentStep.focusTarget
    }

    /// 현재 단계의 메인 버튼 제목
    var primaryButtonTitle: String {
        currentStep.primaryButtonTitle
    }

    /// 건너뛰기 버튼 표시 여부
    var showsSkipButton: Bool {
        currentStep.showsSkipButton
    }

    /// 현재 단계가 "이제 직접 시작하기" 단계인지 여부
    var isReadyToStartStep: Bool {
        currentStep.isReadyToStartStep
    }

    /// 현재 단계가 종료 단계인지 여부
    var isCompletedStep: Bool {
        currentStep.isCompletedStep
    }

    /// 현재 표시 중인 진행 단계 번호
    var visibleStepNumber: Int? {
        currentStep.visibleStepNumber
    }

    /// 전체 표시 단계 수
    var totalVisibleSteps: Int {
        currentStep.totalVisibleSteps
    }

    /// 진행률 (0.0 ~ 1.0)
    var progressValue: Double {
        guard let visibleStepNumber else { return 1.0 }
        guard totalVisibleSteps > 0 else { return 0.0 }
        return Double(visibleStepNumber) / Double(totalVisibleSteps)
    }

    // MARK: - Public Methods

    /// 튜토리얼 시작
    /// - Parameters:
    ///   - tutorialKey: 튜토리얼 식별 키
    ///   - forceStart: 이미 완료한 튜토리얼이어도 강제로 다시 시작할지 여부
    func startTutorial(
        tutorialKey: String,
        forceStart: Bool = false
    ) {
        self.tutorialKey = tutorialKey

        if hasSeenTutorial(for: tutorialKey), !forceStart {
            isActive = false
            isFinished = true
            return
        }

        isActive = true
        isFinished = false
        isSkipped = false
        currentStep = .storyIntro
    }

    /// 메인 버튼 탭 처리
    /// - 일반 단계에서는 다음 단계로 이동
    /// - readyToStart 단계에서는 튜토리얼 완료 처리
    /// - completed 단계에서는 종료 처리
    func handlePrimaryButtonTap() {
        guard isActive else { return }

        switch currentStep {
        case .completed:
            closeTutorial()
        default:
            moveToNextStep()
        }
    }

    /// 이전 단계로 이동
    func goToPreviousStep() {
        guard isActive else { return }
        guard let previousStep = currentStep.previousStep else { return }

        currentStep = previousStep
    }

    /// 튜토리얼 건너뛰기
    func skipTutorial() {
        guard isActive else { return }

        isSkipped = true
        saveTutorialCompletionIfNeeded()
        closeTutorial()
    }

    /// 튜토리얼 상태 초기화
    func resetTutorial() {
        isActive = false
        isFinished = false
        isSkipped = false
        currentStep = .storyIntro
        tutorialKey = nil
    }

    /// 강제로 다시 보기 시작
    func restartTutorial(tutorialKey: String) {
        resetSavedTutorialIfNeeded(for: tutorialKey)
        startTutorial(tutorialKey: tutorialKey, forceStart: true)
    }

    // MARK: - Private Methods

    /// 다음 단계로 이동
    private func moveToNextStep() {
        guard let nextStep = currentStep.nextStep else {
            saveTutorialCompletionIfNeeded()
            closeTutorial()
            return
        }

        currentStep = nextStep

        // completed 단계에 도달하면 저장만 해두고
        // 실제 닫기는 사용자가 버튼을 한 번 더 누를 때 하도록 유지할 수도 있지만,
        // 지금 구조는 readyToStart 이후 바로 종료가 더 자연스럽기 때문에
        // completed 단계는 내부 안전장치 정도로만 둡니다.
        if nextStep == .completed {
            saveTutorialCompletionIfNeeded()
            closeTutorial()
        }
    }

    /// 튜토리얼 종료
    private func closeTutorial() {
        isActive = false
        isFinished = true
    }

    /// 저장된 튜토리얼 완료 여부 확인
    private func hasSeenTutorial(for key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    /// 튜토리얼 완료 저장
    private func saveTutorialCompletionIfNeeded() {
        guard let tutorialKey else { return }
        UserDefaults.standard.set(true, forKey: tutorialKey)
    }

    /// 저장된 완료 상태 초기화
    private func resetSavedTutorialIfNeeded(for key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
