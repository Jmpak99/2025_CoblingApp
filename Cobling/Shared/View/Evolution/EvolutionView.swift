//
//  EvolutionView.swift
//  Cobling
//
//  Created by 박종민 on 3/1/26.
//

import SwiftUI
import UIKit

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Evolution Data
enum EvolutionStage: String {
    case egg, kid, cobling, legend
    var assetName: String { "cobling_stage_\(rawValue)" }
}

private func fromToStage(reachedLevel: Int) -> (from: EvolutionStage, to: EvolutionStage) {
    switch reachedLevel {
    case 5:  return (.egg, .kid)
    case 10: return (.kid, .cobling)
    case 15: return (.cobling, .legend)
    default:
        if reachedLevel >= 15 { return (.cobling, .legend) }
        if reachedLevel >= 10 { return (.kid, .cobling) }
        if reachedLevel >= 5  { return (.egg, .kid) }
        return (.egg, .egg)
    }
}

private func evolutionTexts(reachedLevel: Int) -> (title: String, subtitle: String, quote: String) {
    switch reachedLevel {
    case 5:
        return ("Lv 5 달성!", "코블링이 한 단계 성장했어요.", "“이제는 멈추고 생각할 수 있어.”")
    case 10:
        return ("Lv 10 달성!", "코블링의 형태가 완성됐어요.", "“내 안에 흐름이 보이기 시작해!”")
    case 15:
        return ("Lv 15 달성!", "전설의 코블링이 깨어났어요.", "“이 숲의 규칙… 내가 다시 쓸게.”")
    default:
        return ("진화!", "코블링이 변화하고 있어요.", "“더 강해졌어!”")
    }
}

// MARK: - Background Particle
private struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var drift: CGFloat
    var duration: Double
    var delay: Double
}

// MARK: - Explosion Spark
private struct Spark: Identifiable {
    let id = UUID()
    var angle: Double     // radians
    var distance: CGFloat
    var size: CGFloat
}

// MARK: - Evolution View
struct EvolutionView: View {

    let reachedLevel: Int
    let onCompleted: () -> Void

    // Overlay / Card
    @State private var bgOpacity: Double = 0.0
    @State private var cardScale: CGFloat = 0.92

    // Glow
    @State private var glowOpacity: Double = 0.0
    @State private var glowPulse: CGFloat = 1.0

    // Swap
    @State private var swapDone: Bool = false

    // Flash (soft bloom)
    @State private var flashOpacity: Double = 0.0
    @State private var flashScale: CGFloat = 0.85

    // After bounce
    @State private var afterPop: CGFloat = 0.0

    // Particles
    @State private var particles: [Particle] = []

    // Sparks
    @State private var sparks: [Spark] = []
    @State private var showSparks: Bool = false
    @State private var sparkProgress: CGFloat = 0.0   // 0 -> 1 (burst out)

    // Finish
    @State private var isFinishing: Bool = false

    // UX: 애니메이션 도중 버튼 잠깐 비활성화(원치 않으면 false로 고정해도 됩니다)
    @State private var canTapComplete: Bool = false

    // Haptics
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let hapticSoft  = UIImpactFeedbackGenerator(style: .soft)

    private var stages: (from: EvolutionStage, to: EvolutionStage) {
        fromToStage(reachedLevel: reachedLevel)
    }

    private var texts: (title: String, subtitle: String, quote: String) {
        evolutionTexts(reachedLevel: reachedLevel)
    }

    var body: some View {
        ZStack {

            Color.black.opacity(bgOpacity)
                .ignoresSafeArea()

            particleLayer()

            VStack(spacing: 16) {

                Text(texts.title)
                    .font(.pretendardBold24)
                    .foregroundColor(.black)

                Text(texts.subtitle)
                    .font(.pretendardMedium14)
                    .foregroundColor(Color(hex: "333333"))

                ZStack {

                    // Base glow
                    Circle()
                        .fill(Color(hex: "FFD475").opacity(0.32))
                        .frame(width: 210, height: 210)
                        .scaleEffect(glowPulse)
                        .opacity(glowOpacity)
                        .blur(radius: 0.5)

                    // Character (swap)
                    if !swapDone {
                        Image(stages.from.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .blur(radius: flashOpacity > 0.35 ? 3.5 : 0)
                            .opacity(flashOpacity > 0.55 ? 0.92 : 1.0)
                    } else {
                        Image(stages.to.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .scaleEffect(1.0 + afterPop)
                    }

                    // Soft bloom flash (radial gradient + blur)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "FFF7D6").opacity(1.0),
                                    Color(hex: "FFF7D6").opacity(0.55),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 150
                            )
                        )
                        .frame(width: 270, height: 270)
                        .scaleEffect(flashScale)
                        .opacity(flashOpacity)
                        .blur(radius: 18)

                    // Sparks (progress-based burst)
                    if showSparks {
                        ForEach(sparks) { spark in
                            Circle()
                                .fill(Color.white)
                                .frame(width: spark.size, height: spark.size)
                                .offset(
                                    x: cos(spark.angle) * (spark.distance * sparkProgress),
                                    y: sin(spark.angle) * (spark.distance * sparkProgress)
                                )
                                .opacity(Double(1.0 - sparkProgress) * 0.95)
                                .scaleEffect(0.9 + (0.25 * (1.0 - sparkProgress)))
                                .blur(radius: 0.6)
                        }
                    }
                }

                Text(texts.quote)
                    .font(.pretendardMedium14)
                    .foregroundColor(Color(hex: "444444"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)

                Button {
                    finishEvolution()
                } label: {
                    Text(isFinishing ? "처리 중..." : "진화 완료")
                        .font(.pretendardMedium16)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FFD475"))
                        .cornerRadius(12)
                        .opacity((isFinishing || !canTapComplete) ? 0.6 : 1.0)
                }
                .disabled(isFinishing || !canTapComplete)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(22)
            .padding(.horizontal, 36)
            .scaleEffect(cardScale)
        }
        .onAppear {
            // haptic 준비(정확도 향상)
            hapticLight.prepare()
            hapticHeavy.prepare()
            hapticSoft.prepare()

            buildParticles()
            buildSparks()
            playIntroAnimation()
        }
    }

    // MARK: - Animation Sequence
    private func playIntroAnimation() {

        canTapComplete = false
        swapDone = false
        showSparks = false
        sparkProgress = 0.0
        glowPulse = 1.0
        glowOpacity = 0.0
        flashOpacity = 0.0
        flashScale = 0.85
        afterPop = 0.0

        // 등장(여유 있게)
        withAnimation(.easeInOut(duration: 0.35)) {
            bgOpacity = 0.60
            cardScale = 1.0
        }

        // 글로우 서서히
        withAnimation(.easeInOut(duration: 0.75).delay(0.20)) {
            glowOpacity = 1.0
        }

        Task { @MainActor in

            // Before 인지 시간(여유)
            try? await Task.sleep(nanoseconds: 850_000_000)

            // 1) Flash 시작(너무 하얗게 “컷” 나지 않게 최대치 살짝 낮춤)
            hapticLight.impactOccurred()

            withAnimation(.easeOut(duration: 0.65)) {
                flashOpacity = 0.92
                flashScale = 1.12
            }

            // flash가 충분히 덮인 뒤 스왑 (끊김 최소화)
            try? await Task.sleep(nanoseconds: 520_000_000)

            // 2) 스왑 + 폭발
            hapticHeavy.impactOccurred()

            swapDone = true
            showSparks = true
            sparkProgress = 0.0

            withAnimation(.easeOut(duration: 0.30)) {
                glowPulse = 1.22
            }

            // sparks burst out
            withAnimation(.easeOut(duration: 0.55)) {
                sparkProgress = 1.0
            }

            // 3) flash 잔광(천천히 꺼지게) + 글로우도 원래로
            try? await Task.sleep(nanoseconds: 420_000_000)

            withAnimation(.easeInOut(duration: 1.05)) {
                flashOpacity = 0.0
                flashScale = 1.0
                glowPulse = 1.0
            }

            // 4) After bounce (스프링이 더 “손맛”)
            try? await Task.sleep(nanoseconds: 520_000_000)

            hapticSoft.impactOccurred()

            withAnimation(.interpolatingSpring(stiffness: 380, damping: 18)) {
                afterPop = 0.10
            }

            try? await Task.sleep(nanoseconds: 220_000_000)

            withAnimation(.easeOut(duration: 0.28)) {
                afterPop = 0.0
            }

            // 5) sparks 정리
            try? await Task.sleep(nanoseconds: 550_000_000)
            showSparks = false

            // 버튼 활성화
            canTapComplete = true
        }
    }

    // MARK: - Particles
    private func buildParticles() {
        particles = (0..<14).map { _ in
            Particle(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.1...0.7),
                size: CGFloat.random(in: 2...4),
                opacity: Double.random(in: 0.10...0.22),
                drift: CGFloat.random(in: -16...16),
                duration: Double.random(in: 1.4...2.3),
                delay: Double.random(in: 0...0.9)
            )
        }
    }

    @ViewBuilder
    private func particleLayer() -> some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(Color.white.opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .position(
                            x: geo.size.width * p.x,
                            y: geo.size.height * p.y
                        )
                        .modifier(ParticleFloat(drift: p.drift, duration: p.duration, delay: p.delay))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private struct ParticleFloat: ViewModifier {
        let drift: CGFloat
        let duration: Double
        let delay: Double
        @State private var up = false

        func body(content: Content) -> some View {
            content
                .offset(y: up ? drift : -drift)
                .animation(
                    .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                        .delay(delay),
                    value: up
                )
                .onAppear { up = true }
        }
    }

    // MARK: - Sparks
    private func buildSparks() {
        sparks = (0..<12).map { _ in
            Spark(
                angle: Double.random(in: 0...(2 * .pi)),
                distance: CGFloat.random(in: 70...130),
                size: CGFloat.random(in: 4...6)
            )
        }
    }

    // MARK: - Finish
    private func finishEvolution() {
        guard !isFinishing else { return }
        isFinishing = true

        Task {
            await markEvolutionAsCompletedOnServer()

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    cardScale = 0.95
                    bgOpacity = 0.0
                    glowOpacity = 0.0
                    flashOpacity = 0.0
                }
            }

            try? await Task.sleep(nanoseconds: 250_000_000)

            await MainActor.run {
                isFinishing = false
                onCompleted()
            }
        }
    }

    private func markEvolutionAsCompletedOnServer() async {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData(
                    ["character": ["evolutionPending": false]],
                    merge: true
                )
        } catch {
            print("❌ Evolution pending=false update failed:", error.localizedDescription)
        }
        #endif
    }
}

#if DEBUG
struct EvolutionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EvolutionView(reachedLevel: 5, onCompleted: {})
            EvolutionView(reachedLevel: 10, onCompleted: {})
            EvolutionView(reachedLevel: 15, onCompleted: {})
        }
    }
}
#endif
