//
//  ContributionThanksView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Preview 감지
private enum BuildEnv {
    static let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

// MARK: - Model
struct ContributionThanksItem: Identifiable {
    let id: String
    let title: String
    let contributorsText: String
    let date: Date
}

// MARK: - ViewModel
@MainActor
final class ContributionThanksViewModel: ObservableObject {
    @Published var items: [ContributionThanksItem] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private var listener: ListenerRegistration?

    func start() {
        isLoading = true
        errorMessage = nil

        let db = Firestore.firestore()

        listener = db.collection("contributionThanks")
            .whereField("isPublished", isEqualTo: true)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    self.errorMessage = err.localizedDescription
                    self.isLoading = false
                    return
                }

                let docs = snap?.documents ?? []
                self.items = docs.compactMap { doc in
                    let data = doc.data()

                    let title = (data["title"] as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    let contributorsText = (data["contributorsText"] as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    let ts = data["date"] as? Timestamp
                    let date = ts?.dateValue() ?? Date()

                    guard !title.isEmpty else { return nil }

                    return ContributionThanksItem(
                        id: doc.documentID,
                        title: title,
                        contributorsText: contributorsText,
                        date: date
                    )
                }

                self.isLoading = false
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    // ✅ Preview/테스트용: 외부에서 상태 주입
    func setPreviewState(items: [ContributionThanksItem], isLoading: Bool = false, errorMessage: String? = nil) {
        self.items = items
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
}

// MARK: - View
struct ContributionThanksView: View {
    @StateObject private var vm: ContributionThanksViewModel

    // “나도 기여하기” 화면 연결 (프로젝트에 맞게 교체)
    @State private var showContributeSheet = false

    // 튜닝 값
    private let headerTopPadding: CGFloat = 50
    private let titleToDescSpacing: CGFloat = 30
    private let descToButtonSpacing: CGFloat = 30
    private let buttonWidth: CGFloat = 200
    private let buttonHeight: CGFloat = 56
    private let headerBottomPadding: CGFloat = 50

    // 기본 init (실사용)
    init() {
        _vm = StateObject(wrappedValue: ContributionThanksViewModel())
    }

    // Preview/테스트 init (상태 주입용)
    init(previewItems: [ContributionThanksItem]) {
        let m = ContributionThanksViewModel()
        m.setPreviewState(items: previewItems)
        _vm = StateObject(wrappedValue: m)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            VStack(spacing: 0) {
                Text("기여해 주신 분")
                    .font(.leeseoyun48)
                    .foregroundColor(.black)
                    .padding(.top, headerTopPadding)

                Text("주신 아이디어가 서비스에 반영이 된다면\n해당 페이지에 업데이트 됩니다. :)")
                    .font(.pretendardMedium16)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, titleToDescSpacing)

                Button {
                    showContributeSheet = true
                } label: {
                    Text("나도 기여하기")
                        .font(.pretendardBold18)
                        .foregroundColor(.black)
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(Color(hex: "FFD475"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.top, descToButtonSpacing)
                .padding(.bottom, headerBottomPadding)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)

            // MARK: - List Area
            Group {
                if vm.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("불러오는 중…")
                            .font(.pretendardMedium14)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 28)

                } else if let msg = vm.errorMessage {
                    VStack(spacing: 10) {
                        Text("불러오기에 실패했어요")
                            .font(.pretendardBold16)
                            .foregroundColor(.black)

                        Text(msg)
                            .font(.pretendardMedium14)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 28)

                } else if vm.items.isEmpty {
                    EmptyThanksView(
                        onTapContribute: { showContributeSheet = true }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 28)

                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.items) { item in
                                ContributionThanksRow(item: item)
                                Divider()
                                    .background(Color.black.opacity(0.08))
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // ✅ Preview에서는 Firestore 호출 금지
            guard !BuildEnv.isPreview else { return }
            vm.start()
        }
        .onDisappear {
            guard !BuildEnv.isPreview else { return }
            vm.stop()
        }
        .sheet(isPresented: $showContributeSheet) {
            NavigationStack {
                ContributionFormView()
            }
        }
    }
}

// MARK: - Empty State View
private struct EmptyThanksView: View {
    var onTapContribute: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("아직 등록된 기여가 없어요")
                .font(.pretendardBold16)
                .foregroundColor(.black)

            Text("첫 번째 기여자가 되어주세요! 😊")
                .font(.pretendardMedium14)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Row UI
private struct ContributionThanksRow: View {
    let item: ContributionThanksItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.pretendardBold16)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.contributorsText.isEmpty {
                    Text(item.contributorsText)
                        .font(.pretendardMedium14)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            Text(item.date, formatter: Self.dateFormatter)
                .font(.pretendardMedium14)
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func mockDate(_ yyyyMMdd: String) -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: yyyyMMdd) ?? Date()
    }
}

// MARK: - Previews
#Preview("✅ 리스트 있음") {
    NavigationStack {
        ContributionThanksView(previewItems: [
            .init(
                id: "mock-0",
                title: "무음 셔터 아이디어 제공",
                contributorsText: "@xsu_bix, sozi__1126, catchme_1fyoucann,\nsooyeol2g, n.y_oon, aininniny",
                date: ContributionThanksRow.mockDate("2024-07-18")
            ),
            .init(
                id: "mock-1",
                title: "카메라 촬영, 플래쉬 타이밍 조정",
                contributorsText: "@김영훈, 황진석",
                date: ContributionThanksRow.mockDate("2024-07-13")
            )
        ])
    }
}

#Preview("✅ 첫 번째 기여자(빈 리스트)") {
    NavigationStack {
        ContributionThanksView(previewItems: [])
    }
}
