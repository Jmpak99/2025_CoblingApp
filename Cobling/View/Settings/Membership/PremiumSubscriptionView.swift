//
//  PremiumSubscriptionView.swift
//  Cobling
//
//  Created by 박종민 on 3/4/26.
//

import SwiftUI
import SafariServices // ✅ [추가] 인앱 Safari(SFSafariViewController) 사용



struct PremiumSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    // 선택된 플랜
    @State private var selectedPlan: PremiumPlan = .yearly

    // 현재 프리미엄 결제중 여부 + 현재 플랜(임시)
    // - 나중에 StoreKit/Firestore 값으로 교체
    @State private var isPremiumActive: Bool = true
    @State private var currentPlan: PremiumPlan = .monthly

    // 코블링 메인 컬러(프로젝트 컬러에 맞게 사용)
    private let coblingGreen = Color(hex: "#FFD27B")

    // ✅ [추가] 인앱 Safari 띄우기 상태 + 선택된 URL
    @State private var showSafari = false
    @State private var selectedURL: URL? = nil

    // ✅ [추가] 각각 다른 URL
    private let termsURL = URL(string: "https://certain-exoplanet-9bc.notion.site/Cobling-Terms-of-Service-31720a2218b1807e9cf0e802f279e0bd?source=copy_link")!
    private let privacyURL = URL(string: "https://certain-exoplanet-9bc.notion.site/Cobling-Privacy-Policy-31720a2218b1808783b3da4379d1ec9f?source=copy_link")!

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {

                    header

                    Spacer().frame(height: 8)

                    hero
                    benefitsSection
                    plansSection
                    subscribeButton
                    footerNotice

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .navigationBarHidden(true)
        }
        // ✅ [추가] 앱 안에서 Safari 열기
        .sheet(isPresented: $showSafari) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }
    }

    // 현재 선택 플랜이 “현재 플랜”인지
    private var isCurrentSelectedPlan: Bool {
        isPremiumActive && selectedPlan == currentPlan
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44, alignment: .center)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("프리미엄 구독")
                .font(.pretendardBold18)
                .foregroundColor(.black)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    // MARK: - Hero
    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 46, weight: .bold))
                .foregroundColor(.black.opacity(0.9))
                .padding(.top, 10)

            Text("프리미엄 멤버십")
                .font(.pretendardBold28)
                .foregroundColor(.black)

            Text("특별한 혜택을 누리세요")
                .font(.pretendardMedium16)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    // MARK: - Benefits
    private var benefitsSection: some View {
        VStack(spacing: 12) {
            PremiumBenefitCard(
                iconSystemName: "xmark",
                title: "광고 제거",
                subtitle: "플레이 중 나오는 광고가 제거됩니다"
            )

            PremiumBenefitCard(
                iconSystemName: "sparkles",
                title: "EXP +5% 보너스",
                subtitle: "클리어 경험치에 5% 보너스가 적용돼요"
            )

            PremiumBenefitCard(
                iconSystemName: "book.closed",
                title: "추가 챕터 (시즌 2–3)",
                subtitle: "프리미엄 전용 시즌 콘텐츠를 이용할 수 있어요"
            )
        }
        .padding(.top, 6)
    }

    // MARK: - Plans
    private var plansSection: some View {
        VStack(spacing: 12) {

            PremiumPlanCard(
                title: "연간 구독",
                subtitle: "1년마다 결제",
                priceText: "₩29,000",
                unitText: "/년",
                highlightText: "월 ₩2,417으로 더 저렴하게!",
                isSelected: selectedPlan == .yearly,
                showCurrentBadge: isPremiumActive && currentPlan == .yearly,
                badgeColor: coblingGreen
            )
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedPlan = .yearly
            }

            PremiumPlanCard(
                title: "월간 구독",
                subtitle: "1개월마다 결제",
                priceText: "₩3,300",
                unitText: "/월",
                highlightText: nil,
                isSelected: selectedPlan == .monthly,
                showCurrentBadge: isPremiumActive && currentPlan == .monthly,
                badgeColor: coblingGreen
            )
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedPlan = .monthly
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button {
            // ✅ TODO: StoreKit 결제 연결 시 여기서 purchase 실행
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            Text(buttonTitle)
                .font(.pretendardBold18)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isCurrentSelectedPlan ? Color.black.opacity(0.35) : Color.black)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
        .disabled(isCurrentSelectedPlan)
        .opacity(isCurrentSelectedPlan ? 0.9 : 1.0)
    }

    private var buttonTitle: String {
        if isCurrentSelectedPlan {
            return "현재 이용 중인 플랜입니다"
        }
        switch selectedPlan {
        case .yearly:  return "구독하기 - ₩29,000"
        case .monthly: return "구독하기 - ₩3,300"
        }
    }

    // MARK: - Footer Notice
    private var footerNotice: some View {
        VStack(spacing: 10) {

            // ✅ [수정] 이용약관/개인정보처리방침을 AttributedString 링크로 처리
            Text(makePolicyText())
                .font(.pretendardMedium12)              // ✅ 기존 폰트 유지
                .foregroundColor(.gray)                  // ✅ 색상 유지
                .tint(.gray)                             // ✅ 링크 색상도 회색 유지(요청: 색상 바꾸지 말기)
                .multilineTextAlignment(.center)
                .environment(\.openURL, OpenURLAction { url in
                    switch url.absoluteString {
                    case "terms":
                        selectedURL = termsURL
                        showSafari = true
                        return .handled
                    case "privacy":
                        selectedURL = privacyURL
                        showSafari = true
                        return .handled
                    default:
                        return .systemAction
                    }
                })

            VStack(spacing: 6) {
                Text("• 구독은 자동 갱신됩니다")
                Text("• 갱신 24시간 전에 취소하지 않으면 자동으로 갱신됩니다")
                Text("• 구독은 언제든지 App Store에서 관리 및 취소할 수 있습니다")
            }
            .font(.pretendardMedium10)                  // ✅ 기존 폰트 유지
            .foregroundColor(.gray.opacity(0.9))        // ✅ 기존 색상 유지
        }
        .multilineTextAlignment(.center)
        .padding(.top, 6)
    }

    // ✅ [추가] 약관 문구 AttributedString 생성 (살짝 굵게 + 밑줄)
    private func makePolicyText() -> AttributedString {
        var result = AttributedString("구매 시 ")

        // 이용약관 (SemiBold + Underline + 링크)
        var terms = AttributedString("이용약관")
        terms.link = URL(string: "terms")
        terms.font = .pretendardSemiBold12            // ✅ 살짝 굵게
        terms.underlineStyle = .single                // ✅ 밑줄

        let middle = AttributedString(" 및 ")

        // 개인정보처리방침 (SemiBold + Underline + 링크)
        var privacy = AttributedString("개인정보처리방침")
        privacy.link = URL(string: "privacy")
        privacy.font = .pretendardSemiBold12          // ✅ 살짝 굵게
        privacy.underlineStyle = .single              // ✅ 밑줄

        let tail = AttributedString("에 동의하게 됩니다.")

        result.append(terms)
        result.append(middle)
        result.append(privacy)
        result.append(tail)

        return result
    }
}

// MARK: - Plan Enum
private enum PremiumPlan {
    case yearly
    case monthly
}

// MARK: - Benefit Card
private struct PremiumBenefitCard: View {
    let iconSystemName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconSystemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pretendardSemiBold18)
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.pretendardMedium14)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(hex: "#F3F3F3"))
        .cornerRadius(16)
    }
}

// MARK: - Plan Card
private struct PremiumPlanCard: View {
    let title: String
    let subtitle: String
    let priceText: String
    let unitText: String
    let highlightText: String?
    let isSelected: Bool

    let showCurrentBadge: Bool
    let badgeColor: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text(title)
                    .font(.pretendardSemiBold22)
                    .foregroundColor(.black)

                if showCurrentBadge {
                    Text("현재 플랜")
                        .font(.pretendardSemiBold12)
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(badgeColor)
                        .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(priceText)
                        .font(.pretendardSemiBold22)
                        .foregroundColor(.black)

                    Text(unitText)
                        .font(.pretendardMedium14)
                        .foregroundColor(.gray)
                }
            }

            HStack {
                Text(subtitle)
                    .font(.pretendardMedium14)
                    .foregroundColor(.gray)
                Spacer()
            }

            Divider().opacity(0.25)

            if let highlightText {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)

                    Text(highlightText)
                        .font(.pretendardBold14)
                        .foregroundColor(.black.opacity(0.75))

                    Spacer()
                }
            }
        }
        .padding(18)
        .background(Color(hex: "#F3F3F3"))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
        )
    }
}

#Preview("프리미엄 구독") {
    NavigationStack {
        PremiumSubscriptionView()
    }
}
