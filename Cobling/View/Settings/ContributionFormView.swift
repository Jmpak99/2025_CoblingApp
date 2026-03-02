//
//  ContributionFormView.swift
//  Cobling
//
//  Created by 박종민 on 3/2/26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Preview 감지
private enum BuildEnv {
    static let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

// MARK: - 타입(버그/아이디어)
enum ContributionType: String, CaseIterable {
    case bug = "버그 제보"
    case idea = "아이디어 제안"
}

@MainActor
final class ContributionFormViewModel: ObservableObject {
    // 입력값
    @Published var nickname: String = ""
    @Published var type: ContributionType = .idea
    @Published var content: String = ""

    // UI 상태
    @Published var isSubmitting: Bool = false
    @Published var alertMessage: String? = nil
    @Published var didSubmit: Bool = false

    // 제한
    let nicknameLimit: Int = 15
    let contentLimit: Int = 500

    // 버튼 활성 조건
    var canSubmit: Bool {
        let nick = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return !isSubmitting
        && !nick.isEmpty
        && !body.isEmpty
        && nick.count <= nicknameLimit
        && body.count <= contentLimit
    }

    func enforceLimits() {
        if nickname.count > nicknameLimit {
            nickname = String(nickname.prefix(nicknameLimit))
        }
        if content.count > contentLimit {
            content = String(content.prefix(contentLimit))
        }
    }

    func submit() async {
        guard canSubmit else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        // Preview에서는 저장 안 함
        guard !BuildEnv.isPreview else {
            self.didSubmit = true
            return
        }

        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? "unknown"

        let data: [String: Any] = [
            "nickname": nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            "type": type.rawValue, // "버그 제보" / "아이디어 제안"
            "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
            "uid": uid,
            "createdAt": FieldValue.serverTimestamp()
        ]

        do {
            try await db.collection("contributionSubmissions").addDocument(data: data)
            self.didSubmit = true
        } catch {
            self.alertMessage = error.localizedDescription
        }
    }
}

// MARK: - View
struct ContributionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ContributionFormViewModel()

    // 디자인 값(스크린샷 느낌)
    private let horizontalPadding: CGFloat = 22
    private let fieldCornerRadius: CGFloat = 12

    var body: some View {
        VStack(spacing: 0) {
            // 상단 영역(네비게이션 느낌)
            headerBar

            ScrollView {
                VStack(alignment: .leading, spacing: 34) {

                    // 닉네임
                    VStack(alignment: .leading, spacing: 10) {
                        Text("*닉네임 (최대 15자)")
                            .font(.pretendardBold18)
                            .foregroundColor(.black)

                        TextField("닉네임을 입력해주세요", text: $vm.nickname)
                            .font(.pretendardMedium16)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: fieldCornerRadius)
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                            .onChange(of: vm.nickname) { _ in vm.enforceLimits() }
                    }

                    // 기여 유형 + 설명
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Text("*기여 유형")
                                .font(.pretendardBold18)
                                .foregroundColor(.black)

                        }

                        // 라디오 버튼 2개
                        VStack(spacing: 14) {
                            RadioRow(
                                title: ContributionType.bug.rawValue,
                                isSelected: vm.type == .bug
                            ) { vm.type = .bug }

                            RadioRow(
                                title: ContributionType.idea.rawValue,
                                isSelected: vm.type == .idea
                            ) { vm.type = .idea }
                        }
                        .padding(.top, 4)
                    }

                    // 내용
                    VStack(alignment: .leading, spacing: 10) {
                        Text("*내용 (최대500자)")
                            .font(.pretendardBold18)
                            .foregroundColor(.black)

                        ZStack(alignment: .topLeading) {
                            // TextEditor
                            TextEditor(text: $vm.content)
                                .font(.pretendardMedium16)
                                .padding(10)
                                .frame(height: 220)
                                .background(Color.clear)
                                .onChange(of: vm.content) { _ in vm.enforceLimits() }

                            // Placeholder
                            if vm.content.isEmpty {
                                Text("내용을 입력해주세요")
                                    .font(.pretendardMedium16)
                                    .foregroundColor(.gray.opacity(0.55))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 18)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: fieldCornerRadius)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )

                        // 카운트(오른쪽 아래)
                        HStack {
                            Spacer()
                            Text("\(vm.content.count)/\(vm.contentLimit)")
                                .font(.pretendardMedium14)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    }

                    // 버튼이랑 겹치지 않게 여백
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 18)
            }

            // 하단 제출 버튼(스크린샷처럼 고정)
            submitBar
        }
        .background(Color.white)
        .ignoresSafeArea(.keyboard)
        .alert("알림", isPresented: Binding(
            get: { vm.alertMessage != nil },
            set: { if !$0 { vm.alertMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(vm.alertMessage ?? "")
        }
        .onChange(of: vm.didSubmit) { did in
            if did {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                dismiss()
            }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 44, height: 44, alignment: .center)
            }

            Spacer()

            Text("기여하기")
                .font(.pretendardBold18)
                .foregroundColor(.black)

            Spacer()

            // 오른쪽 균형 맞추기용 더미
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color.white)
    }

    // MARK: - Submit Bar
    private var submitBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.15)

            Button {
                Task { await vm.submit() }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(vm.canSubmit ? Color.black.opacity(0.75) : Color.black.opacity(0.25))

                    if vm.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("제출하기")
                            .font(.pretendardBold18)
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 56)
            }
            .disabled(!vm.canSubmit)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.white)
        }
    }
}

// MARK: - Radio Row
private struct RadioRow: View {
    let title: String
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) { // 약간 간격도 줄임
                ZStack {
                    Circle()
                        .stroke(Color.black, lineWidth: 1.5)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(title)
                    .font(.pretendardMedium16)
                    .foregroundColor(.black)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("기여하기 폼") {
    NavigationStack {
        ContributionFormView()
    }
}
