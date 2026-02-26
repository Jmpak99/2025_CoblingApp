//
//  ChapterCutsceneView.swift
//  Cobling
//
//  Created by 박종민 on 2/26/26.
//

import SwiftUI

struct ChapterCutsceneView: View {
    let cutscene: ChapterCutscene
    let onClose: () -> Void
    
    @EnvironmentObject var authVM: AuthViewModel

    @State private var index: Int = 0

    private var currentLine: DialogueLine {
        cutscene.lines[min(index, cutscene.lines.count - 1)]
    }

    private var isLast: Bool {
        index >= cutscene.lines.count - 1
    }
    
    // 현재 유저 stage 기반 cobling 에셋 이름
    // 우선순위:
    // 1) userProfile.character.stage가 유효하면 무조건 그걸 사용
    // 2) stage가 비정상/없으면 cutscene.coblingAssetName fallback
    // 3) 그것도 없으면 egg
    private var resolvedCoblingAssetName: String {
        let stage = (authVM.userProfile?.character.stage ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let allowed: Set<String> = ["egg", "kid", "cobling", "legend"]
        if allowed.contains(stage) {
            return "cobling_stage_\(stage)"
        }

        if let fromCutscene = cutscene.coblingAssetName, !fromCutscene.isEmpty {
            return fromCutscene
        }

        return "cobling_stage_egg"
    }

    // 배경 페이드 인
    @State private var backgroundOpacity: Double = 0.0

    // 캐릭터 등장 애니메이션(슬라이드+페이드)
    @State private var leftCharacterOffsetX: CGFloat = -90
    @State private var rightCharacterOffsetX: CGFloat = 90
    @State private var charactersOpacity: Double = 0.0

    // 말풍선 타이핑 효과 상태
    @State private var displayedText: String = ""
    @State private var isTyping: Bool = false
    @State private var typingTask: Task<Void, Never>? = nil

    // 타이핑 속도
    private let typingInterval: UInt64 = 28_000_000 // 0.028s
    
    private func visualScale(for assetName: String) -> CGFloat {
        // 에셋마다 투명 여백/비율이 달라서 보이는 크기를 맞추기 위한 보정값
        // - 처음엔 기본 1.0으로 두고, 눈으로 보면서 조금씩 조절하면 됩니다.
        switch assetName {
        case "cobling_stage_egg":
            return 0.60
        case "spirit_forest":
            return 1.00

        // 나중에 stage가 늘어나면 여기만 추가
        case "cobling_stage_kid":
            return 0.94
        case "cobling_stage_cobling":
            return 0.98
        case "cobling_stage_legend":
            return 1.00

        default:
            return 1.00
        }
    }

    var body: some View {

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // 캐릭터 높이: 세로 기준 비율 고정
            let characterHeight = h * 0.28

            // 대사 박스가 차지하는 하단 안전 높이(겹침 방지)
            // 🔥 더 위로 올리고 싶으면 값을 "더 크게" 하시면 됩니다.
            let dialogueBottomPadding: CGFloat = 130   // (대사 박스 자체를 더 위로)
            let dialogueReservedHeight: CGFloat = 300 // (캐릭터/배경을 더 위로)

            ZStack {
                // MARK: - Background
                ZStack {
                    Image("bg_ch1_intro")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipped()
                        .ignoresSafeArea()
                        .opacity(backgroundOpacity)

                    // 가독성용 딤
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()
                        .opacity(backgroundOpacity)
                }

                // MARK: - Characters
                VStack {
                    Spacer()

                    HStack(alignment: .bottom) {
                        // Left: Cobling
                        characterImage(
                            assetName: resolvedCoblingAssetName,
                            isActive: currentLine.speaker == .cobling,
                            isLeft: true
                        )
                        .frame(height: characterHeight)
                        .offset(x: leftCharacterOffsetX)
                        .opacity(charactersOpacity)

                        Spacer(minLength: 12)

                        // Right: Spirit
                        characterImage(
                            assetName: cutscene.spiritAssetName ?? "spirit_forest",
                            isActive: currentLine.speaker == .spirit,
                            isLeft: false
                        )
                        .frame(height: characterHeight)
                        .offset(x: rightCharacterOffsetX)
                        .opacity(charactersOpacity)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, dialogueReservedHeight) // ✅ 캐릭터를 대사박스만큼 위로
                }

                // MARK: - Dialogue Box
                VStack {
                    Spacer()

                    CutsceneDialogueBox(
                        speakerName: currentLine.speaker.displayName,
                        text: displayedText,
                        isLast: isLast,
                        primaryButtonTitle: cutscene.type.primaryButtonTitle,
                        isTyping: isTyping,
                        onNext: handleNextAction,
                        onPrimary: {
                            typingTask?.cancel()
                            typingTask = nil
                            onClose()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, dialogueBottomPadding) // ✅ 대사박스 자체를 더 위로
                }
            }
            .frame(width: w, height: h)
            .contentShape(Rectangle())
            .onTapGesture {
                handleNextAction()
            }
            .onAppear {
                startIntroAnimations()
                startTyping(for: currentLine.text)
            }
            .onChange(of: index) { _ in
                startTyping(for: currentLine.text)
            }
            .onDisappear {
                typingTask?.cancel()
                typingTask = nil
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Animations
    private func startIntroAnimations() {
        backgroundOpacity = 0.0
        charactersOpacity = 0.0
        leftCharacterOffsetX = -90
        rightCharacterOffsetX = 90

        withAnimation(.easeInOut(duration: 0.35)) {
            backgroundOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                charactersOpacity = 1.0
                leftCharacterOffsetX = 0
                rightCharacterOffsetX = 0
            }
        }
    }

    // MARK: - Flow
    private func handleNextAction() {
        if isTyping {
            finishTypingImmediately()
            return
        }

        if !isLast {
            advance()
            return
        }

        // 마지막은 버튼으로 닫기
    }

    private func advance() {
        guard index < cutscene.lines.count - 1 else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            index += 1
        }
    }

    // MARK: - Typing
    private func startTyping(for fullText: String) {
        typingTask?.cancel()
        typingTask = nil

        displayedText = ""
        isTyping = true

        let text = fullText

        typingTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 40_000_000)

            for ch in text {
                if Task.isCancelled { return }
                displayedText.append(ch)
                try? await Task.sleep(nanoseconds: typingInterval)
            }

            isTyping = false
            typingTask = nil
        }
    }

    private func finishTypingImmediately() {
        typingTask?.cancel()
        typingTask = nil
        displayedText = currentLine.text
        isTyping = false
    }

    // MARK: - Character Image
    @ViewBuilder
    private func characterImage(assetName: String, isActive: Bool, isLeft: Bool) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .scaleEffect(visualScale(for: assetName))
            .scaleEffect(isActive ? 1.03 : 0.97)                 // 기존 강조 연출
            .opacity(isActive ? 1.0 : 0.55)
            .shadow(color: .black.opacity(isActive ? 0.35 : 0.15),
                    radius: isActive ? 10 : 4, x: 0, y: 6)
            .animation(.easeOut(duration: 0.18), value: isActive)
            .accessibilityLabel(Text(isLeft ? "코블링" : "정령"))
    }
}

// MARK: - Local DialogueBox (Shared/DialogueBox와 충돌 없게 별도 구현)
private struct CutsceneDialogueBox: View {
    let speakerName: String
    let text: String
    let isLast: Bool
    let primaryButtonTitle: String
    let isTyping: Bool

    let onNext: () -> Void
    let onPrimary: () -> Void
    
    // 숨쉬는(펄스) 애니메이션 상태
    @State private var pulse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(speakerName)
                .font(.pretendardBold18) // ✅ 약간 키움
                .opacity(0.95)

            // 대사 폰트/크기 업 + 라인 간격 업
            Text(text)
                .font(.pretendardMedium18)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()

                if isLast {
                    Button(action: onPrimary) {
                        HStack(spacing: 8) {
                            Text(primaryButtonTitle) // "시작하기" / "계속하기"
                                .font(.pretendardBold18)
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.92))
                        )
                        .foregroundColor(.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                        
                        // 펄스 효과(크기 + 밝기 살짝)
                        .scaleEffect(pulse ? 1.03 : 1.0)
                        .opacity(pulse ? 1.0 : 0.92)
                    }
                    .buttonStyle(.plain)
                    
                    // 마지막 대사일 때만 애니메이션 시작
                    .onAppear {
                        pulse = false
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                    }
                    
                    // 마지막이 아니게 되면(인덱스 이동) 애니메이션 정지
                    .onChange(of: isLast) { newValue in
                        if newValue {
                            pulse = false
                            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                pulse = true
                            }
                        } else {
                            pulse = false
                        }
                    }
                    
                } else {
                    Button(action: onNext) {
                        HStack(spacing: 6) {
                            Text(isTyping ? "스킵" : "다음")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Image(systemName: isTyping ? "forward.fill" : "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .foregroundColor(.white)
    }
}
