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

    // UI전용 : 퍼펙트 클리어 여부
    let perfectClear: Bool

    // 1서브퀘스트(챕터 첫 진입) 판별용 order
    let order: Int
}

// 챕터 컷씬 데이터 제공자 (Dialogue.swift의 DialogueLine/DialogueSpeaker 사용)
private enum ChapterCutsceneProvider {

    // 챕터별 배경 에셋
    static func backgroundAssetName(chapterId: String) -> String? {
        switch chapterId.lowercased() {
        case "ch1": return "bg_ch1_intro"
        default: return nil
        }
    }

    // QuestDetail에서 띄울 cutscene 생성 (intro 전용)
    static func introCutscene(chapterId: String) -> ChapterCutscene {
        ChapterCutscene(
            chapterId: chapterId,
            type: .intro,
            lines: ChapterDialogueStore.lines(chapterId: chapterId, type: .intro), // Store에서 가져오기
            backgroundAssetName: backgroundAssetName(chapterId: chapterId),
            coblingAssetName: "cobling_stage_egg",
            spiritAssetName: "spirit_forest"
        )
    }
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

    // 인트로를 거쳐서 진입하기 위한 대기값
    @State private var pendingSubQuestId: String? = nil

    // fullScreenCover로 컷씬 표시 여부
    @State private var showChapterCutscene: Bool = false

    var body: some View {
        ZStack {

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

                QuestBlockView(
                    chapterId: chapter.id,
                    subQuestId: subQuestId,

                    onGoNextSubQuest: { nextId in
                        currentSubQuestId = nextId
                    },

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
        // "진짜 전체화면" 챕터 컷씬 (탭바 완전 차단 + 배경 전체 덮기)
        // =================================================
        .fullScreenCover(isPresented: $showChapterCutscene) {
            ChapterCutsceneView(
                cutscene: ChapterCutsceneProvider.introCutscene(chapterId: chapter.id), // Store 기반 provider로 통일
                onClose: {
                    // 인트로 1회 표시 처리(UserDefaults → LocalStorageManager로 통일)
                    LocalStorageManager.setCutsceneShown(chapterId: chapter.id, type: .intro)

                    // 컷씬 종료 후 실제 진입
                    if let target = pendingSubQuestId {
                        currentSubQuestId = target
                    }
                    pendingSubQuestId = nil
                    showChapterCutscene = false

                    // 컷씬 닫히고 게임 들어가면 탭바 계속 숨김 유지(QuestBlockView에서 이미 숨김 처리 가능)
                    tabBarViewModel.isTabBarVisible = false
                }
            )
            .ignoresSafeArea()
            .onAppear {
                // 탭바 완전 차단
                tabBarViewModel.isTabBarVisible = false
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

            // 리스트 화면에서는 탭바 노출
            // (게임 진입 시 QuestBlockView에서 숨김 처리 중)
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

        // 첫 서브퀘스트 + 인트로 미시청이면 -> fullScreenCover 컷씬부터
        // UserDefaults 기반 → LocalStorageManager 기반으로 통일
        let didShowIntro = LocalStorageManager.isCutsceneShown(chapterId: chapter.id, type: .intro)
        if quest.order == 1 && !didShowIntro {
            pendingSubQuestId = quest.id
            showChapterCutscene = true
            return
        }

        // 바로 게임 진입
        currentSubQuestId = quest.id
    }

    // =================================================
    // MARK: - Firestore 로드 & 병합
    // =================================================
    private func loadSubQuests() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }

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

                    // order 로드 (Int/Double 안전 처리)
                    let order = data["order"] as? Int ?? Int(data["order"] as? Double ?? 9999)

                    return SubQuest(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        state: .locked,
                        perfectClear: false,
                        order: order
                    )
                } ?? []

                // 유저 progress 로드
                db.collection("users")
                    .document(userId)
                    .collection("progress")
                    .document(chapter.id)
                    .collection("subQuests")
                    .getDocuments { progressSnap, _ in

                        // state map
                        var progressStateMap: [String: String] = [:]

                        // perfectClear map
                        var perfectClearMap: [String: Bool] = [:]

                        progressSnap?.documents.forEach { doc in
                            let data = doc.data()

                            progressStateMap[doc.documentID] =
                                (data["state"] as? String)?
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    ?? "locked"

                            perfectClearMap[doc.documentID] = data["perfectClear"] as? Bool ?? false
                        }

                        // 3️⃣ 병합
                        self.subQuests = baseSubQuests.map { sq in
                            let stateStr = progressStateMap[sq.id] ?? "locked"

                            let state: SubQuestState = {
                                switch stateStr {
                                case "completed": return .completed
                                case "inProgress": return .inProgress
                                default: return .locked
                                }
                            }()

                            // perfectClear도 병합
                            let perfectClear = perfectClearMap[sq.id] ?? false

                            return SubQuest(
                                id: sq.id,
                                title: sq.title,
                                description: sq.description,
                                state: state,
                                perfectClear: perfectClear,
                                order: sq.order
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

        // 퍼펙트 클리어면 icon_perfectClear
        if subQuest.state == .completed && subQuest.perfectClear {
            return "icon_perfectClear"
        }

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
