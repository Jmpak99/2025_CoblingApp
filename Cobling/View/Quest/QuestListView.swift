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
    @Published var quests: [(QuestDocument, QuestStatus)] = []
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

            var results: [(QuestDocument, QuestStatus)] = []

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
                    .document(doc.documentID) // chapterId

                let subSnap = try await progressRef.collection("subQuests").getDocuments()
                let states = subSnap.documents.map { $0.data()["state"] as? String ?? "locked" }

                // 3) 상태 집계
                let status: QuestStatus
                if states.allSatisfy({ $0 == "completed" }) && !states.isEmpty {
                    status = .completed
                } else if states.contains("inProgress") {
                    status = .inProgress
                } else {
                    status = .locked
                }

                results.append((quest, status))
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
                        ForEach(viewModel.quests, id: \.0.id) { (quest, status) in
                            QuestCardWrapper_DB(
                                quest: quest,
                                status: status,
                                showLockedAlert: $showLockedAlert
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                
            }
        }
        .alert(isPresented: $showLockedAlert) {
            Alert(title: Text("잠긴 퀘스트입니다"))
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
    @Binding var showLockedAlert: Bool

    var body: some View {
        let bgColor = QuestTheme.backgroundColor(order: quest.order)

        let card = ZStack {
            QuestCardView_DB(
                title: quest.title,
                subtitle: quest.subtitle,
                status: status
            )
        }
        .frame(width: 335, height: 220)
        .background(bgColor) // ✅ 카드 전체 배경
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

// MARK: - 카드 뷰 (DB 기반)
struct QuestCardView_DB: View {
    let title: String
    let subtitle: String
    let status: QuestStatus

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

                        Image(status.iconName)
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

// MARK: - Preview
struct QuestListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuestListView()
        }
    }
}
