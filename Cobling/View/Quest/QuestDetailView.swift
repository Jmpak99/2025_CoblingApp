//
//  QuestDetailView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - 하위 퀘스트 상태
enum SubQuestState {
    case completed, inProgress, locked
}

// MARK: - 뷰 전용 모델
struct SubQuest: Identifiable {
    let id: String
    let title: String
    let description: String
    let state: SubQuestState
}

// MARK: - QuestDetailView
struct QuestDetailView: View {

    // MARK: - 전달받는 값
    let chapter: QuestDocument

    // MARK: - Environment
    @EnvironmentObject var tabBarViewModel: TabBarViewModel
    @Environment(\.dismiss) private var dismiss   // 리스트로 바로 돌아가기

    // MARK: - State
    @State private var subQuests: [SubQuest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    // 🔑 현재 플레이 중인 서브퀘스트 ID
    // nil이면 리스트 화면
    @State private var currentSubQuestId: String? = nil
    @State private var showLockedAlert = false
    
    var body: some View {
        ZStack {
            
            //QuestTheme.backgroundColor(order: chapter.order)
                        //.ignoresSafeArea()

            // =================================================
            // 📋 서브퀘스트 리스트 화면
            // =================================================
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // -------------------------
                    // 챕터 타이틀
                    // -------------------------
                    Text(chapter.title)
                        .font(.gmarketBold34)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 18)

                    Spacer().frame(height: 32)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("코블링의 퀘스트")
                            .font(.pretendardBold24)
                            .padding(.bottom, 4)

                        Text("코블링과 함께 문제를 해결해 보세요!")
                            .font(.pretendardBold14)
                            .foregroundColor(.gray)
                    }

                    // -------------------------
                    // 상태별 UI
                    // -------------------------
                    if isLoading {
                        ProgressView("불러오는 중...")
                            .padding()
                    } else if let errorMessage = errorMessage {
                        Text("에러: \(errorMessage)")
                            .foregroundColor(.red)
                    } else {
                        VStack(spacing: 16) {
                            subQuestList
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: 600)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 80)
            }

            // =================================================
            // 🎮 QuestBlockView (단일, overlay)
            // =================================================
            if let subQuestId = currentSubQuestId {

                // ❗️ push ❌
                // ❗️ QuestDetailView 위에 overlay로 단 하나만 존재
                QuestBlockView(
                    chapterId: chapter.id,
                    subQuestId: subQuestId,

                    // ✅ 다음 서브퀘스트로 이동
                    // → QuestBlockView가 직접 이동하지 않고
                    // → 상태 변경 요청만 함
                    onGoNextSubQuest: { nextId in
                        currentSubQuestId = nextId
                    },

                    // ✅ 나가기
                    // → 즉시 리스트 화면으로 복귀
                    onExitToList: {
                        currentSubQuestId = nil
                        dismiss()
                    }
                )
                .zIndex(10)
                .transition(.move(edge: .trailing))
            }
        }

        // =================================================
        // MARK: - Alert
        // =================================================
        .alert("잠긴 퀘스트입니다", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) { }
        }

        // =================================================
        // MARK: - Lifecycle
        // =================================================
        .onAppear {
            loadSubQuests()

            // 🔥 리스트 화면에서는 탭바 노출
            tabBarViewModel.isTabBarVisible = true
        }

        .navigationBarTitleDisplayMode(.inline)
    }

    // =================================================
    // MARK: - 하위 퀘스트 리스트
    // =================================================
    private var subQuestList: some View {
        let bgColor = QuestTheme.backgroundColor(order: chapter.order)

        return ForEach(subQuests, id: \.id) { quest in
            SubQuestCard(
                subQuest: quest,
                backgroundColor: bgColor,
                onTap: {
                    handleSubQuestTap(quest)
                }
            )
        }
    }

    // =================================================
    // MARK: - 하위 퀘스트 선택
    // =================================================
    private func handleSubQuestTap(_ quest: SubQuest) {

        // 잠김 상태면 알럿
        if quest.state == .locked {
            showLockedAlert = true
            return
        }

        // 🔥 NavigationLink ❌
        // 🔥 상태 변경 ⭕️
        currentSubQuestId = quest.id
    }

    // =================================================
    // MARK: - Firestore 로드 & 병합
    // =================================================
    private func loadSubQuests() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // 1️⃣ 마스터 데이터 로드
        db.collection("quests")
            .document(chapter.id)
            .collection("subQuests")
            .order(by: "order")
            .getDocuments { snapshot, error in

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }

                let baseSubQuests: [SubQuest] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return SubQuest(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        state: .locked
                    )
                } ?? []

                // 2️⃣ 유저 progress 로드
                db.collection("users")
                    .document(userId)
                    .collection("progress")
                    .document(chapter.id)
                    .collection("subQuests")
                    .getDocuments { progressSnap, _ in

                        var progressMap: [String: String] = [:]

                        progressSnap?.documents.forEach { doc in
                            progressMap[doc.documentID] =
                                (doc.data()["state"] as? String)?
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                ?? "locked"
                        }

                        // 3️⃣ 병합
                        self.subQuests = baseSubQuests.map { sq in
                            let stateStr = progressMap[sq.id] ?? "locked"

                            let state: SubQuestState = {
                                switch stateStr {
                                case "completed": return .completed
                                case "inProgress": return .inProgress
                                default: return .locked
                                }
                            }()

                            return SubQuest(
                                id: sq.id,
                                title: sq.title,
                                description: sq.description,
                                state: state
                            )
                        }

                        self.isLoading = false
                    }
            }
    }
}

// MARK: - 하위 퀘스트 카드
struct SubQuestCard: View {
    let subQuest: SubQuest
    let backgroundColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .frame(width: 355, height: 60)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subQuest.title)
                                    .font(.gmarketBold16)
                                    .foregroundColor(.black)
                                
                                Text(subQuest.description)
                                    .font(.pretendardRegular14)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(statusIconName)
                                .resizable()
                                .frame(width: subQuest.state == .inProgress ? 83 : 70,
                                       height: 30)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                VStack { Spacer() }.frame(height: 80)
            }
            .frame(width: 355, height: 140)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusIconName: String {
        switch subQuest.state {
        case .completed: return "icon_completed"
        case .inProgress: return "icon_inProgress"
        case .locked: return "icon_lock"
        }
    }
}

// MARK: - Preview
struct QuestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuestDetailView(
                chapter: QuestDocument(
                    id: "ch1",
                    title: "잠든 알의 속삭임",
                    subtitle: "깨어날 시간이에요, 코블링",
                    order: 1,
                    recommendedLevel: 1,
                    isActive: true
                )
            )
        }
    }
}

