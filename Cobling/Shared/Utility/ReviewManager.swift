//
//  ReviewManager.swift
//  Cobling
//
//  Created by 박종민 on 3/10/26.
//

import Foundation
import StoreKit
import UIKit

@MainActor
final class ReviewManager: ObservableObject {
    static let shared = ReviewManager()

    @Published var shouldShowReviewPopup: Bool = false
    @Published var currentMilestone: Int? = nil

    private let subQuestClearCountKey = "review.subQuestClearCount"
    private let reviewRequestedMilestonesKey = "review.requestedMilestones"
    private let reviewMilestones: Set<Int> = [5, 15, 30]

    private init() {}

    var currentClearCount: Int {
        UserDefaults.standard.integer(forKey: subQuestClearCountKey)
    }

    var requestedMilestones: Set<Int> {
        let array = UserDefaults.standard.array(forKey: reviewRequestedMilestonesKey) as? [Int] ?? []
        return Set(array)
    }

    func recordSubQuestCompletion() {
        let newCount = currentClearCount + 1
        UserDefaults.standard.set(newCount, forKey: subQuestClearCountKey)

        checkReviewTrigger(for: newCount)
    }

    func checkReviewTrigger(for count: Int) {
        guard reviewMilestones.contains(count) else { return }
        guard !hasRequestedReview(for: count) else { return }

        currentMilestone = count
        shouldShowReviewPopup = true
        markReviewRequested(for: count)
    }

    func handlePositiveFeedback() {
        shouldShowReviewPopup = false
        requestAppStoreReview() // "좋았어요" 선택 시 시스템 리뷰창 요청
    }

    func handleNegativeFeedback() {
        shouldShowReviewPopup = false
    }

    func dismissPopup() {
        shouldShowReviewPopup = false
    }

    func hasRequestedReview(for milestone: Int) -> Bool {
        requestedMilestones.contains(milestone)
    }

    private func markReviewRequested(for milestone: Int) {
        var updated = requestedMilestones
        updated.insert(milestone)
        UserDefaults.standard.set(Array(updated).sorted(), forKey: reviewRequestedMilestonesKey)
    }

    private func requestAppStoreReview() { // 실제 App Store 리뷰 요청 함수
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene) // iOS 기본 리뷰창 호출
    }

    func resetAllReviewData() {
        UserDefaults.standard.removeObject(forKey: subQuestClearCountKey)
        UserDefaults.standard.removeObject(forKey: reviewRequestedMilestonesKey)
        shouldShowReviewPopup = false
        currentMilestone = nil
    }

    func setClearCountForDebug(_ count: Int) {
        UserDefaults.standard.set(count, forKey: subQuestClearCountKey)
    }
}
