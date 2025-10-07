//
//  QuestDetailView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI
import FirebaseFirestore

//
//  QuestDetailView.swift
//  Cobling
//

import SwiftUI
import FirebaseFirestore

// MARK: - 하위 퀘스트 상태
enum SubQuestState {
    case completed, inProgress, locked
}

// MARK: - Firestore 서브퀘스트 원본 모델
struct SubQuestDocument: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var state: String            // "completed", "inProgress", "locked"
    var order: Int?
    var isActive: Bool?
}

// ✅ SubQuest(뷰 모델) → SubQuestDocument(문서 모델) 변환 이니셜라이저
extension SubQuestDocument {
    init(from viewModel: SubQuest) {
        self.id = viewModel.id
        self.title = viewModel.title
        self.description = viewModel.description
        switch viewModel.state {
        case .completed: self.state = "completed"
        case .inProgress: self.state = "inProgress"
        case .locked:    self.state = "locked"
        }
        self.order = nil
        self.isActive = nil
    }
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
    let chapter: QuestDocument
    
    @State private var subQuests: [SubQuest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedSubQuest: SubQuest? = nil
    @State private var isNavigatingToBlock = false
    @State private var showLockedAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // 챕터 타이틀
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
                
                if isLoading {
                    ProgressView("불러오는 중...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("에러: \(errorMessage)")
                        .foregroundColor(.red)
                } else {
                    VStack(spacing: 16) {
                        subQuestList   // ✅ 분리된 ForEach 뷰
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Spacer(minLength: 40)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .alert("잠긴 퀘스트입니다", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) {}
        }
        .overlay(
            Group {
                if let sub = selectedSubQuest {
                    // ✅ SubQuest → SubQuestDocument로 변환해서 전달
                    NavigationLink(
                        destination: QuestBlockView(subQuest: SubQuestDocument(from: sub)),
                        isActive: $isNavigatingToBlock
                    ) { EmptyView() }
                }
            }
        )
        .onAppear {
            loadSubQuests()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 분리된 ForEach (타입체크 단순화)
    private var subQuestList: some View {
        let bgColor = chapterBackgroundColor
        return ForEach(subQuests, id: \.id) { quest in
            SubQuestCard(
                subQuest: quest,
                backgroundColor: bgColor,
                onTap: { handleSubQuestTap(quest) }
            )
        }
    }
    
    // MARK: - 챕터 배경색(순환 규칙: FFEEEF → FFF1DB → E3EDFB)
    private var chapterBackgroundColor: Color {
        let idx = (chapter.order ?? 0) % 3
        switch idx {
        case 0: return Color(hex: "#FFEEEF")
        case 1: return Color(hex: "#FFF1DB")
        default: return Color(hex: "#E3EDFB")
        }
    }
    
    // MARK: - 하위 퀘스트 선택 핸들러
    private func handleSubQuestTap(_ quest: SubQuest) {
        if quest.state == .locked {
            showLockedAlert = true
        } else {
            selectedSubQuest = quest
            DispatchQueue.main.async {
                isNavigatingToBlock = true
            }
        }
    }
    
    // MARK: - Firestore 로드
    private func loadSubQuests() {
        let db = Firestore.firestore()
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
                
                if let docs = snapshot?.documents {
                    self.subQuests = docs.compactMap { doc in
                        let data = doc.data()
                        let stateStr = data["state"] as? String ?? "locked"
                        let state: SubQuestState
                        switch stateStr {
                        case "completed": state = .completed
                        case "inProgress": state = .inProgress
                        default: state = .locked
                        }
                        
                        return SubQuest(
                            id: doc.documentID,
                            title: data["title"] as? String ?? "",
                            description: data["description"] as? String ?? "",
                            state: state
                        )
                    }
                }
                self.isLoading = false
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
                                .frame(width: subQuest.state == .inProgress ? 83 : 70, height: 30)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                VStack { Spacer() }.frame(height: 80)
            }
            .frame(width: 355, height: 140)
            .background(backgroundColor)
            .background(Color(hex: backgroundColorHex))
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
    
    private var backgroundColorHex: String {
        switch subQuest.state {
        case .completed: return "FFEEEF"
        case .inProgress: return "E3EDFB"
        case .locked: return "FFF1DB"
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
