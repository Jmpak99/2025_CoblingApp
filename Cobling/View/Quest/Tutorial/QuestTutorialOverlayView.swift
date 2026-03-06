//
//  QuestTutorialOverlayView.swift
//  Cobling
//
//  Created by 박종민 on 3/6/26.
//


import SwiftUI

struct QuestTutorialOverlayView: View {
    @ObservedObject var viewModel: QuestTutorialViewModel

    /// 화면에서 강조할 대상들의 frame 정보
    let storyButtonFrame: CGRect?
    let blockPaletteFrame: CGRect?
    let blockCanvasFrame: CGRect?
    let playButtonFrame: CGRect?
    let stopButtonFrame: CGRect?
    let flagFrame: CGRect?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                tutorialDimmedBackground(in: geometry)

                if let highlightFrame = currentHighlightFrame {
                    let expanded = expandedFrame(from: highlightFrame)

                    TutorialHighlightBox(
                        frame: expanded,
                        cornerRadius: currentCornerRadius
                    )
                    .transition(.opacity)
                }

                QuestTutorialBubbleView(viewModel: viewModel)
                    .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Background
private extension QuestTutorialOverlayView {
    @ViewBuilder
    func tutorialDimmedBackground(in geometry: GeometryProxy) -> some View {
        if let highlightFrame = currentHighlightFrame {
            DimmedOverlayWithCutout(
                highlightFrame: expandedFrame(from: highlightFrame),
                cornerRadius: 18
            )
            .ignoresSafeArea()
        } else {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
        }
    }

    var currentHighlightFrame: CGRect? {
        switch viewModel.focusTarget {
        case .storyButton:
            return storyButtonFrame
        case .blockPalette:
            return blockPaletteFrame
        case .blockCanvas:
            return blockCanvasFrame
        case .playButton:
            return playButtonFrame
        case .stopButton:
            return stopButtonFrame
        case .flag:
            return flagFrame
        case .none:
            return nil
        }
    }
    
    var currentCornerRadius: CGFloat {
        switch viewModel.focusTarget {
        case .flag:
            return 22
        default:
            return 18
        }
    }

    func expandedFrame(from frame: CGRect) -> CGRect {
        switch viewModel.focusTarget {
        case .flag:
            return frame.insetBy(dx: -16, dy: -16) // 깃발은 더 넉넉하게
        default:
            return frame.insetBy(dx: -8, dy: -8)
        }
    }
}

// MARK: - Highlight Box
private struct TutorialHighlightBox: View {
    let frame: CGRect
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.white, lineWidth: 3)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )
            .frame(width: frame.width, height: frame.height)
            .position(
                x: frame.midX,
                y: frame.midY
            )
            .shadow(color: .white.opacity(0.45), radius: 16, x: 0, y: 0)
            .allowsHitTesting(false)
    }
}

// MARK: - Dimmed Overlay With Cutout
private struct DimmedOverlayWithCutout: View {
    let highlightFrame: CGRect
    let cornerRadius: CGFloat

    var body: some View {
        Canvas { context, size in
            let fullRect = CGRect(origin: .zero, size: size)
            let overlayPath = Path(fullRect)

            let cutoutPath = Path(
                roundedRect: highlightFrame,
                cornerRadius: cornerRadius
            )

            var combined = overlayPath
            combined.addPath(cutoutPath)

            context.fill(
                combined,
                with: .color(Color.black.opacity(0.45)),
                style: FillStyle(eoFill: true)
            )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color(hex: "#F8F4EC").ignoresSafeArea()

        VStack {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.5))
                    .frame(width: 70, height: 44)

                Spacer()

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.5))
                    .frame(width: 70, height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.top, 80)

            Spacer()

            HStack(alignment: .bottom, spacing: 20) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.25))
                    .frame(width: 120, height: 260)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.18))
                    .frame(width: 190, height: 260)
            }

            Spacer()
        }

        QuestTutorialOverlayPreviewWrapper()
    }
}

private struct QuestTutorialOverlayPreviewWrapper: View {
    @StateObject private var viewModel = QuestTutorialViewModel()

    var body: some View {
        QuestTutorialOverlayView(
            viewModel: viewModel,
            storyButtonFrame: CGRect(x: 28, y: 86, width: 70, height: 44),
            blockPaletteFrame: CGRect(x: 36, y: 360, width: 120, height: 260),
            blockCanvasFrame: CGRect(x: 186, y: 360, width: 190, height: 260),
            playButtonFrame: CGRect(x: 306, y: 86, width: 70, height: 44),
            stopButtonFrame: CGRect(x: 306, y: 146, width: 70, height: 44),
            flagFrame: CGRect(x: 292, y: 268, width: 34, height: 34)
        )
        .onAppear {
            viewModel.startTutorial(
                tutorialKey: "tutorial.quest.ch1.sq1",
                forceStart: true
            )
        }
    }
}
