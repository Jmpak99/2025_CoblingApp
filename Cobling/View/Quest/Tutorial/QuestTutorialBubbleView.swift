//
//  QuestTutorialBubbleView.swift
//  Cobling
//
//  Created by 박종민 on 3/6/26.
//

import SwiftUI

struct QuestTutorialBubbleView: View {
    @ObservedObject var viewModel: QuestTutorialViewModel

    private var canGoBack: Bool {
        viewModel.currentStep.previousStep != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 헤더
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(viewModel.title)
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    if let step = viewModel.visibleStepNumber {
                        Text("\(step)/\(viewModel.totalVisibleSteps)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                ProgressView(value: viewModel.progressValue)
                    .tint(Color(hex: "#6B8F5D"))
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider()

            // MARK: - 본문
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.message)
                    .font(.body)
                    .foregroundColor(Color(hex: "#3A3A3A"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)

            Divider()

            // MARK: - 버튼 영역
            HStack(spacing: 10) {
                Button {
                    viewModel.goToPreviousStep()
                } label: {
                    Text("이전")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(canGoBack ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.12))
                        )
                }
                .disabled(!canGoBack)

                if viewModel.showsSkipButton {
                    Button {
                        viewModel.skipTutorial()
                    } label: {
                        Text("건너뛰기")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#FFF2DC"))
                            )
                    }
                }

                Button {
                    viewModel.handlePrimaryButtonTap()
                } label: {
                    Text(viewModel.primaryButtonTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#6B8F5D"))
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    QuestTutorialBubblePreviewWrapper()
        .padding()
        .background(Color.gray.opacity(0.2))
}

private struct QuestTutorialBubblePreviewWrapper: View {
    @StateObject private var viewModel = QuestTutorialViewModel()

    var body: some View {
        QuestTutorialBubbleView(viewModel: viewModel)
            .onAppear {
                viewModel.startTutorial(
                    tutorialKey: "tutorial.quest.ch1.sq1",
                    forceStart: true
                )
            }
    }
}
