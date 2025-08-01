//
//  QuestListView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

struct Quest: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let status: QuestStatus
    let backgroundColor: Color
}

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

// MARK: - Main View

struct QuestListView: View {
    @State private var showLockedAlert = false

    let quests: [Quest] = [
        Quest(title: "잠든 알의 속삭임", subtitle: "깨어날 시간이에요, 코블링", status: .completed, backgroundColor: Color(hex: "#FFEEEF")),
        Quest(title: "코블링의 첫 걸음", subtitle: "한 걸음씩, 함께 나아가요", status: .inProgress, backgroundColor: Color(hex: "#FFF1DB")),
        Quest(title: "반복의 언덕", subtitle: "같은 길도, 다르게 걸어볼까?", status: .locked, backgroundColor: Color(hex: "#E3EDFB")),
        Quest(title: "조건의 문", subtitle: "문을 여는 열쇠는 블록 안에 있어요", status: .locked, backgroundColor: Color(hex: "#FFEEEF")),
    ]

    var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text("퀘스트")
                    .font(.pretendardBold34)
                    .padding(.horizontal)
                    .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(quests) { quest in
                            QuestCardWrapper(quest: quest, showLockedAlert: $showLockedAlert)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden) // 스크롤 바 숨기기
            }
            .navigationBarHidden(true) 
            .alert(isPresented: $showLockedAlert) {
                Alert(title: Text("잠긴 퀘스트입니다"))
            }
        }
}

// MARK: - View 분리 (컴파일 최적화 핵심)

struct QuestCardWrapper: View {
    let quest: Quest
    @Binding var showLockedAlert: Bool

    var body: some View {
        if quest.status == .locked {
            Button(action: {
                showLockedAlert = true
            }) {
                QuestCardView(quest: quest)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            NavigationLink(destination: QuestDetailView(chapter: quest)) {
                QuestCardView(quest: quest)
            }
        }
    }
}

// MARK: - 카드 뷰

struct QuestCardView: View {
    let quest: Quest

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
                            Text(quest.title)
                                .font(.headline)
                                .foregroundColor(.black)
                            Text(quest.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Image(quest.status.iconName)
                            .resizable()
                            .frame(width: quest.status == .inProgress ? 83 : 70, height: 30)
                    }
                    .padding(.horizontal, 16)
                }
            }

            VStack {
                HStack { Spacer() }
                Spacer()
            }
            .frame(height: 125)
        }
        .frame(width: 335, height: 220)
        .background(quest.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
    }
}


// MARK: - Preview

struct QuestListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack{
            QuestListView()
        }
    }
}
