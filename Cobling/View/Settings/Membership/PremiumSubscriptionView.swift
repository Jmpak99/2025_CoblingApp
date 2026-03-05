//
//  PremiumSubscriptionView.swift
//  Cobling
//
//  Created by 박종민 on 3/4/26.
//

import SwiftUI
import SafariServices //  인앱 Safari(SFSafariViewController) 사용

#if canImport(FirebaseAuth)
import FirebaseAuth //  DB 업데이트(테스트용)
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore // DB 업데이트(테스트용)
#endif

struct PremiumSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var authVM: AuthViewModel // AuthViewModel에서 premium 상태를 읽기 위해

    // 선택된 플랜
    @State private var selectedPlan: PremiumPlan = .lifetime

    // 현재 프리미엄 결제중 여부 + 현재 플랜(임시)
    // - 나중에 StoreKit/Firestore 값으로 교체
    @State private var isPremiumActive: Bool = true
    @State private var currentPlan: PremiumPlan = .monthly

    // 코블링 메인 컬러(프로젝트 컬러에 맞게 사용)
    private let coblingGreen = Color(hex: "#FFD27B")

    // 인앱 Safari 띄우기 상태 + 선택된 URL
    @State private var showSafari = false
    @State private var selectedURL: URL? = nil

    // 각각 다른 URL
    private let termsURL = URL(string: "https://certain-exoplanet-9bc.notion.site/Cobling-Terms-of-Service-31720a2218b1807e9cf0e802f279e0bd?source=copy_link")!
    private let privacyURL = URL(string: "https://certain-exoplanet-9bc.notion.site/Cobling-Privacy-Policy-31720a2218b1808783b3da4379d1ec9f?source=copy_link")!
    
    // 플로팅 탭바 높이(프로젝트 값과 동일하게)
    private let floatingTabBarHeight: CGFloat = 72
    
    // 홈 인디케이터/안전영역 하단 inset(가려짐 방지용)
    private var safeAreaBottomInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first?
            .safeAreaInsets.bottom ?? 0
    }
    
    
    // DB에서 읽은 "현재 프리미엄 활성 여부"
    private var dbIsPremiumActive: Bool {
        authVM.userProfile?.premium?.isActive ?? false
    }
    
    // DB에서 읽은 "현재 플랜"
    // - premium.plan이 nil/Null이면 기본값(.monthly)로 처리(원하시면 nil 처리로 바꿔도 됩니다)
    private var dbCurrentPlan: PremiumPlan {
        let raw = authVM.userProfile?.premium?.plan
        return PremiumPlan(fromFirestore: raw) ?? .monthly
    }
    
    // 현재 선택 플랜이 “현재 플랜”인지 (DB 기준)
    private var isCurrentSelectedPlan: Bool {
        dbIsPremiumActive && selectedPlan == dbCurrentPlan
    }

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
                .padding(.bottom, floatingTabBarHeight)
            }
            .navigationBarHidden(true)
        }
        // 화면 진입 시, DB의 현재 플랜을 선택 상태로 맞추기(UX 깔끔)
        .onAppear {
            // 프리미엄 활성이고 plan이 있으면 그걸 선택 상태로 동기화
            // 비활성이라도 plan이 저장돼 있으면 그걸 기본 선택으로 보여줄 수도 있음
            selectedPlan = dbCurrentPlan
        }
        // 앱 안에서 Safari 열기
        .sheet(isPresented: $showSafari) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }
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
                title: "평생 구독",
                subtitle: "1회 결제",
                priceText: "₩29,000",
                unitText: "/영구적",
                highlightText: "한 번 결제로 영구 이용!",
                isSelected: selectedPlan == .lifetime,
                showCurrentBadge: dbIsPremiumActive && dbCurrentPlan == .lifetime, // DB 기준으로 배지
                badgeColor: coblingGreen
            )
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                selectedPlan = .lifetime
            }

            PremiumPlanCard(
                title: "월간 구독",
                subtitle: "1개월마다 결제",
                priceText: "₩3,300",
                unitText: "/월",
                highlightText: nil,
                isSelected: selectedPlan == .monthly,
                showCurrentBadge: dbIsPremiumActive && dbCurrentPlan == .monthly, // DB 기준으로 배지
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
            // TODO: StoreKit 결제 연결 시 여기서 purchase 실행
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            // StoreKit 연결 전까지 "테스트용"으로 DB에 premium 업데이트
            Task {
                await setPremiumInFirestore(plan: selectedPlan)
            }
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
        case .lifetime:  return "구매하기 - ₩29,000"
        case .monthly: return "구독하기 - ₩3,300"
        }
    }

    // MARK: - Footer Notice
    private var footerNotice: some View {
        VStack(spacing: 10) {

            // 이용약관/개인정보처리방침을 AttributedString 링크로 처리
            Text(makePolicyText())
                .font(.pretendardMedium12)
                .foregroundColor(.gray)
                .tint(.gray)
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
                Text("• 월간 구독은 자동 갱신됩니다")
                Text("• 갱신 24시간 전에 취소하지 않으면 자동으로 갱신됩니다")
                Text("• 평생 구독(1회 결제)은 추가 결제 없이 계속 이용할 수 있습니다")
                Text("• 구독은 언제든지 App Store에서 관리 및 취소할 수 있습니다")
            }
            .font(.pretendardMedium10)
            .foregroundColor(.gray.opacity(0.9))
        }
        .multilineTextAlignment(.center)
        .padding(.top, 6)
    }

    //약관 문구 AttributedString 생성 (살짝 굵게 + 밑줄)
    private func makePolicyText() -> AttributedString {
        var result = AttributedString("구매 시 ")

        // 이용약관 (SemiBold + Underline + 링크)
        var terms = AttributedString("이용약관")
        terms.link = URL(string: "terms")
        terms.font = .pretendardSemiBold12
        terms.underlineStyle = .single

        let middle = AttributedString(" 및 ")

        // 개인정보처리방침 (SemiBold + Underline + 링크)
        var privacy = AttributedString("개인정보처리방침")
        privacy.link = URL(string: "privacy")
        privacy.font = .pretendardSemiBold12
        privacy.underlineStyle = .single

        let tail = AttributedString("에 동의하게 됩니다.")

        result.append(terms)
        result.append(middle)
        result.append(privacy)
        result.append(tail)

        return result
    }
    
    // (StoreKit 연결 전) 테스트용: Firestore에 premium 정보 업데이트
    @MainActor
    private func setPremiumInFirestore(plan: PremiumPlan) async {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        let uid = authVM.currentUserId
        guard !uid.isEmpty else { return }

        let userRef = Firestore.firestore().collection("users").document(uid)

        do {
            try await userRef.setData(
                [
                    "premium": [
                        "isActive": true,
                        "plan": plan.firestoreValue, // "monthly"/"yearly"
                        "source": "debug",           // 나중에 "appstore"로 변경
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                ],
                merge: true
            )

            // 저장 직후 UI 반영이 늦을 수 있어서 1회 강제 리프레시(옵션)
            await authVM.refreshUserProfileIfNeeded()
        } catch {
            // 필요하면 authVM.authError로 노출해도 됨
            // authVM.authError = error.localizedDescription
            print("❌ premium update failed:", error.localizedDescription)
        }
        #else
        // Firebase 없는 빌드/프리뷰에서는 아무것도 하지 않음
        #endif
    }
}

// MARK: - Plan Enum
private enum PremiumPlan {
    case lifetime
    case monthly
    
    // Firestore에 저장할 문자열 값
    var firestoreValue: String {
        switch self {
        case .lifetime:  return "lifetime"
        case .monthly: return "monthly"
        }
    }

    // Firestore 문자열 -> PremiumPlan 변환
    init?(fromFirestore raw: String?) {
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty else { return nil }
        switch raw {
        case "lifetime", "lifetime_one_time", "permanent": self = .lifetime
        case "monthly", "month": self = .monthly
        default: return nil
        }
    }
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
            .environmentObject(AuthViewModel()) // 환경오브젝트 주입(크래시 방지)
    }
}
