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
    private let pendingReviewMilestoneKey = "review.pendingMilestone" // 다음 화면에서 띄울 milestone 저장
    private let reviewMilestones: Set<Int> = [5, 15, 30]

    private init() {}

    var currentClearCount: Int {
        UserDefaults.standard.integer(forKey: subQuestClearCountKey)
    }

    var requestedMilestones: Set<Int> {
        let array = UserDefaults.standard.array(forKey: reviewRequestedMilestonesKey) as? [Int] ?? []
        return Set(array)
    }

    var pendingMilestone: Int? {
        let value = UserDefaults.standard.integer(forKey: pendingReviewMilestoneKey)
        return value == 0 ? nil : value
    }

    func recordSubQuestCompletion() {
        let newCount = currentClearCount + 1
        UserDefaults.standard.set(newCount, forKey: subQuestClearCountKey)

        checkReviewTrigger(for: newCount)
    }

    func checkReviewTrigger(for count: Int) {
        guard reviewMilestones.contains(count) else { return }
        guard !hasRequestedReview(for: count) else { return }

        // 지금 바로 팝업 띄우지 않고 "다음 화면에서 띄울 예정"으로 저장만 함
        UserDefaults.standard.set(count, forKey: pendingReviewMilestoneKey)
        markReviewRequested(for: count)
    }

    func consumePendingReviewIfNeeded() { // 다음 스테이지 진입 후 호출
        guard let milestone = pendingMilestone else { return }

        currentMilestone = milestone
        shouldShowReviewPopup = true
        UserDefaults.standard.removeObject(forKey: pendingReviewMilestoneKey)
    }

    func handlePositiveFeedback() {
        shouldShowReviewPopup = false
        requestAppStoreReview()
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

    private func requestAppStoreReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
    }

    func resetAllReviewData() {
        UserDefaults.standard.removeObject(forKey: subQuestClearCountKey)
        UserDefaults.standard.removeObject(forKey: reviewRequestedMilestonesKey)
        UserDefaults.standard.removeObject(forKey: pendingReviewMilestoneKey) 
        shouldShowReviewPopup = false
        currentMilestone = nil
    }

    func setClearCountForDebug(_ count: Int) {
        UserDefaults.standard.set(count, forKey: subQuestClearCountKey)
    }
}
