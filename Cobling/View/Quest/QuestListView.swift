//
//  QuestListView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore 퀘스트 데이터 모델
struct QuestDocument: Identifiable, Codable {
    var id: String             // Firestore 문서 ID
    var title: String
    var subtitle: String
    var order: Int
    var recommendedLevel: Int
    var isActive: Bool
    var allowedBlocks: [String]?
}

// MARK: - Quest 상태
enum QuestStatus {
    case completed, inProgress, locked

    var iconName: String {
        switch self {
        case .completed: return "icon_completed"
        case .inProgress: return "icon_inProgress"
        case .locked: return "icon_lock"
        }
    }
}

// MARK: - ViewModel (Firestore 데이터 로드)
@MainActor
final class QuestListViewModel: ObservableObject {
    @Published var quests: [(QuestDocument, QuestStatus, Bool)] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchQuests() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "로그인 필요"
            self.isLoading = false
            return
        }

        do {
            // 1) quests 전체 가져오기 (order 순으로 정렬)
            let questSnap = try await db.collection("quests")
                .order(by: "order")
                .getDocuments()

            var results: [(QuestDocument, QuestStatus, Bool)] = []

            for doc in questSnap.documents {
                let data = doc.data()
                let quest = QuestDocument(
                    id: doc.documentID,
                    title: data["title"] as? String ?? "",
                    subtitle: data["subtitle"] as? String ?? "",
                    order: data["order"] as? Int ?? 0,
                    recommendedLevel: data["recommendedLevel"] as? Int ?? 1,
                    isActive: data["isActive"] as? Bool ?? false,
                    allowedBlocks: data["allowedBlocks"] as? [String] ?? []
                )

                // 2) 진행상황 불러오기
                let progressRef = db.collection("users")
                    .document(userId)
                    .collection("progress")
                    .document(doc.documentID)

                let subSnap = try await progressRef.collection("subQuests").getDocuments()
                let states: [String] = subSnap.documents.map {
                    ($0.data()["state"] as? String ?? "locked")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }

                let perfectFlags: [Bool] = subSnap.documents.map {
                    $0.data()["perfectClear"] as? Bool ?? false
                }

                // 3) 상태 집계
                let status: QuestStatus
                if states.allSatisfy({ $0 == "completed" }) && !states.isEmpty {
                    status = .completed
                } else if states.contains("inProgress") {
                    status = .inProgress
                } else {
                    status = .locked
                }

                // 챕터 퍼펙트 판정
                let isPerfectChapter =
                    (status == .completed) &&
                    (!perfectFlags.isEmpty) &&
                    perfectFlags.allSatisfy { $0 == true }

                results.append((quest, status, isPerfectChapter))
            }

            self.quests = results
            self.isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Main View
struct QuestListView: View {
    @StateObject private var viewModel = QuestListViewModel()
    @State private var showLockedAlert = false
    @State private var showComingSoonAlert = false

    @EnvironmentObject var tabBarViewModel: TabBarViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("퀘스트")
                .font(.pretendardBold34)
                .padding(.horizontal)
                .padding(.top, 20)

            if viewModel.isLoading {
                ProgressView("불러오는 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                Text("오류: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.quests, id: \.0.id) { (quest, status, isPerfect) in
                            QuestCardWrapper_DB(
                                quest: quest,
                                status: status,
                                isPerfectChapter: isPerfect,
                                showLockedAlert: $showLockedAlert
                            )
                        }

                        // Coming Soon 카드
                        ComingSoonQuestCardWrapper(
                            chapterNumber: 6,
                            title: "새로운 모험이 곧 시작돼요",
                            subtitle: "업데이트를 기다려 주세요",
                            showComingSoonAlert: $showComingSoonAlert
                        )
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
        }
        .alert("잠긴 퀘스트입니다", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) { }
        }
        .alert("Coming Soon", isPresented: $showComingSoonAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("새로운 챕터가 곧 업데이트될 예정입니다 🚀")
        }
        .task {
            await viewModel.fetchQuests()
        }
        .onAppear {
            tabBarViewModel.isTabBarVisible = true
            appState.isInGame = false
        }
    }
}

// MARK: - 카드 Wrapper (DB 기반)
struct QuestCardWrapper_DB: View {
    let quest: QuestDocument
    let status: QuestStatus
    let isPerfectChapter: Bool

    @Binding var showLockedAlert: Bool

    var body: some View {
        let bgColor = QuestTheme.backgroundColor(order: quest.order)

        let card = ZStack {
            QuestCardView_DB(
                title: quest.title,
                subtitle: quest.subtitle,
                status: status,
                isPerfectChapter: isPerfectChapter
            )
        }
        .frame(width: 335, height: 220)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)

        if status == .locked {
            Button {
                showLockedAlert = true
            } label: {
                card
            }
        } else {
            NavigationLink(destination: QuestDetailView(chapter: quest)) {
                card
            }
        }
    }
}

// MARK: - 카드 뷰
struct QuestCardView_DB: View {
    let title: String
    let subtitle: String
    let status: QuestStatus
    let isPerfectChapter: Bool

    private var statusIconName: String {
        if status == .completed && isPerfectChapter {
            return "icon_perfectClear"
        }
        return status.iconName
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 125)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(height: 95)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.black)

                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(statusIconName)
                            .resizable()
                            .frame(
                                width: status == .inProgress ? 83 : 70,
                                height: 30
                            )
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Coming Soon Wrapper
struct ComingSoonQuestCardWrapper: View {
    let chapterNumber: Int
    let title: String
    let subtitle: String

    @Binding var showComingSoonAlert: Bool

    var body: some View {
        Button {
            showComingSoonAlert = true
        } label: {
            ComingSoonQuestCardView(
                chapterNumber: chapterNumber,
                title: title,
                subtitle: subtitle
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coming Soon Card
struct ComingSoonQuestCardView: View {
    let chapterNumber: Int
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {

            // 크기를 키우고, 위로 올려서 카드 상단 영역 중앙에 가깝게 배치
            Text("Coming Soon")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.gray.opacity(0.85))
                .padding(.horizontal, 26)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.7))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                .offset(y: -40) // 위치를 위로 올림

            VStack(spacing: 0) {
                Spacer().frame(height: 125)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.95))
                        .frame(height: 95)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("챕터 \(chapterNumber)")
                                .font(.headline)

                            Text(title)
                                .font(.subheadline)

                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .frame(width: 335, height: 220)
        .background(Color.gray.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    Color.gray.opacity(0.25),
                    style: StrokeStyle(lineWidth: 1, dash: [6])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Preview
struct QuestListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuestListView()
        }
    }
}
