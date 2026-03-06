//
//  QuestTutorialOverlayView.swift
//  Cobling
//
//  Created by 박종민 on 3/6/26.
//

import SwiftUI

struct QuestTutorialBubbleView: View {
    @ObservedObject var viewModel: QuestTutorialViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()
                .overlay(Color.black.opacity(0.06))

            contentSection

            Divider()
                .overlay(Color.black.opacity(0.06))

            bottomButtonSection
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Header
private extension QuestTutorialBubbleView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(viewModel.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                if let current = viewModel.visibleStepNumber {
                    Text("\(current) / \(viewModel.totalVisibleSteps)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.black.opacity(0.55))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.06))
                        )
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.08))
                        .frame(height: 8)

                    Capsule()
                        .fill(Color(hex: "#6B8F5D"))
                        .frame(
                            width: max(8, geo.size.width * viewModel.progressValue),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Content
private extension QuestTutorialBubbleView {
    var contentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.black.opacity(0.82))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if let focusDescription = focusDescriptionText {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6B8F5D"))
                        .padding(.top, 2)

                    Text(focusDescription)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B8F5D"))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    var focusDescriptionText: String? {
        switch viewModel.focusTarget {
        case .storyButton:
            return "스토리 버튼 위치를 눈여겨보세요."
        case .blockPalette:
            return "왼쪽 블록 영역을 확인해보세요."
        case .blockCanvas:
            return "블록을 놓는 오른쪽 캔버스 영역을 확인해보세요."
        case .playButton:
            return "시작 버튼 위치를 확인해보세요."
        case .stopButton:
            return "멈춤 버튼 위치를 확인해보세요."
        case .flag:
            return "깃발이 목표 지점이에요."
        case .none:
            return nil
        }
    }
}

// MARK: - Buttons
private extension QuestTutorialBubbleView {
    var bottomButtonSection: some View {
        HStack(spacing: 10) {
            Button {
                viewModel.goToPreviousStep()
            } label: {
                Text("이전")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(viewModel.currentStep.previousStep == nil ? Color.gray.opacity(0.5) : Color.black.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black.opacity(0.05))
                    )
            }
            .disabled(viewModel.currentStep.previousStep == nil)

            if viewModel.showsSkipButton {
                Button {
                    viewModel.skipTutorial()
                } label: {
                    Text("건너뛰기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.black.opacity(0.72))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: "#FFF2DC"))
                        )
                }
            }

            Button {
                viewModel.handlePrimaryButtonTap()
            } label: {
                Text(viewModel.primaryButtonTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: "#6B8F5D"))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.08).ignoresSafeArea()

        QuestTutorialBubblePreviewWrapper()
            .padding(.horizontal, 8)
    }
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
