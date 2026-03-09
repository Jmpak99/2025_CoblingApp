//
//  EmailSignupView.swift
//  Cobling
//
//  Created by 박종민 on 8/9/25.
//

import SwiftUI
import SafariServices // 인앱 Safari(SFSafariViewController) 사용

// MARK: - In-app Safari
struct SafariView: UIViewControllerRepresentable { // 인앱 Safari 래퍼
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(Color(hex: "#6B8F5D")) // 링크/버튼 틴트(선택)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

struct EmailSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authVM: AuthViewModel

    // 가입 성공 시 부모에서 네비 전환 처리
    var onSignupSuccess: () -> Void = {}

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var isLoading = false
    @State private var errorText: String?

    // 인앱 Safari 띄우기 상태 + 선택된 URL
    @State private var showSafari = false
    @State private var selectedURL: URL? = nil

    // 각각 다른 URL
    private let termsURL = URL(string: "https://certain-exoplanet-9bc.notion.site/Cobling-Terms-of-Service-31720a2218b1807e9cf0e802f279e0bd?source=copy_link")! // 이용약관 URL
    private let privacyURL = URL(string: "https://certain-exoplanet-9bc.notion.site/Cobling-Privacy-Policy-31720a2218b1808783b3da4379d1ec9f?source=copy_link")! // 개인정보처리방침 URL

    private let fieldHeight: CGFloat = 48
    private let fieldRadius: CGFloat = 10

    private var isFormValid: Bool {
        !name.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirm
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 타이틀
                    VStack(alignment: .leading, spacing: 8) {
                        Text("프로필")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.black)
                        Text("가입하는 분의 프로필을 입력해주세요.")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.45))
                    }
                    .padding(.top, 8)

                    Group {
                        fieldLabel("닉네임")
                        inputTextField("닉네임을 입력하세요.", text: $name)

                        fieldLabel("이메일")
                        inputTextField("email@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)

                        fieldLabel("비밀번호")
                        secureNewPasswordField("영어소문자, 숫자 포함 8자 이상", text: $password)

                        fieldLabel("비밀번호 확인")
                        secureConfirmField("영어소문자, 숫자 포함 8자 이상", text: $confirm)
                    }

                    if let e = errorText {
                        Text(e)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }

                    //  Markdown 대신 AttributedString으로 링크 + Bold를 직접 적용 (완전 해결)
                    Text(makePolicyText()) //AttributedString 생성 함수 사용
                        .font(.pretendardMedium12) // (기존 프로젝트 폰트 유지)
                        .foregroundColor(.black.opacity(0.65))
                        .tint(Color(hex: "#6B8F5D")) // 링크 색상 유지
                        .environment(\.openURL, OpenURLAction { url in // 링크 탭 이벤트 가로채기
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

                    Button {
                        Task { await signUp() }
                    } label: {
                        Text(isLoading ? "가입 중..." : "가입하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#2F2F2F")))
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity((!isFormValid || isLoading) ? 0.6 : 1.0)
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        // 앱 안에서 Safari 열기
        .sheet(isPresented: $showSafari) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }

        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
    }

    // MARK: - 약관 문구 AttributedString 생성 (링크 + Bold 확실하게)
    private func makePolicyText() -> AttributedString {
        // 기본 문장
        var result = AttributedString("가입을 완료하실 경우 ")

        // 이용약관 (Bold + 링크)
        var terms = AttributedString("이용약관")
        terms.link = URL(string: "terms") // openURL에서 가로채는 키
        terms.font = .pretendardBold14 // Bold 확실 적용

        // 연결 문구
        let middle = AttributedString(" 및 ")

        // 개인정보처리방침 (Bold + 링크)
        var privacy = AttributedString("개인정보처리방침")
        privacy.link = URL(string: "privacy") // openURL에서 가로채는 키
        privacy.font = .pretendardBold14 // Bold 확실 적용

        // 마무리 문구
        let tail = AttributedString("에 동의하는 것으로 간주합니다.")

        // 합치기
        result.append(terms)
        result.append(middle)
        result.append(privacy)
        result.append(tail)

        return result
    }

    // MARK: - Subviews
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.black)
            .padding(.top, 2)
    }

    private func inputTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.default)
            .padding(.horizontal, 14).frame(height: fieldHeight)
            .background(RoundedRectangle(cornerRadius: fieldRadius).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: fieldRadius).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    // iPad 강력 비번 오버레이 회피용: 새 비밀번호 입력 필드
    private func secureNewPasswordField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.asciiCapable)
            .textContentType(.newPassword)      // 새 비밀번호(제안 유지)
            .padding(.horizontal, 14).frame(height: fieldHeight)
            .background(RoundedRectangle(cornerRadius: fieldRadius).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: fieldRadius).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    // 확인 필드는 AutoFill 오버레이를 끄는 트릭 적용
    private func secureConfirmField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.asciiCapable)
            .textContentType(.oneTimeCode)      // ← 오버레이 비활성화(입력 가로채기 방지)
            .padding(.horizontal, 14).frame(height: fieldHeight)
            .background(RoundedRectangle(cornerRadius: fieldRadius).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: fieldRadius).stroke(Color.black.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Action
    private func signUp() async {
        errorText = nil
        isLoading = true
        do {
            try await authVM.signUp(email: email, password: password, nickname: name)
            onSignupSuccess()                  // 가입 성공
        } catch {
            errorText = authVM.authError ?? error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    EmailSignupView()
        .environmentObject(AuthViewModel())
}
