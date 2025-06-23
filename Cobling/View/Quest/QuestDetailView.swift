//
//  QuestDetailView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

// MARK: - 모델 정의

enum SubQuestState {
    case completed, inProgress, locked
}

struct SubQuest: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let state: SubQuestState
}


// MARK: - 상세화면 View

struct ChapterDetailView: View {
    @State private var showLockedAlert = false

    // 내부 고정 챕터 타이틀
    private let chapterTitle = "잠든 알의 속삭임"

    // 내부 고정 하위 퀘스트 리스트
    private let subQuests: [SubQuest] = [
        SubQuest(title: "잠든 알의 속삭임", description: "무언가 꿈틀거려요. 알 속에서 소리가 나요", state: .completed),
        SubQuest(title: "잠든 알의 속삭임", description: "무언가 꿈틀거려요. 알 속에서 소리가 나요", state: .inProgress),
        SubQuest(title: "잠든 알의 속삭임", description: "무언가 꿈틀거려요. 알 속에서 소리가 나요", state: .locked),
        SubQuest(title: "잠든 알의 속삭임", description: "무언가 꿈틀거려요. 알 속에서 소리가 나요", state: .locked),
        SubQuest(title: "잠든 알의 속삭임", description: "무언가 꿈틀거려요. 알 속에서 소리가 나요", state: .locked),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ✅ 중앙 정렬된 타이틀
            Text(chapterTitle)
                .font(.gmarketBold34)
                .frame(maxWidth: .infinity, alignment: .center) // 가운데 정렬
                .padding(.top)
            
            Spacer().frame(height: 32)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("코블링의 퀘스트")
                    .font(.pretendardBold24)
                    .padding(.bottom, 4)
                Text("코블링과 함께 코딩 문제를 해결해보세요!")
                    .font(.pretendardMedium14)
                    .foregroundColor(.gray)
            }

            

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(subQuests) { quest in
                        SubQuestCard(subQuest: quest) {
                            if quest.state == .locked {
                                showLockedAlert = true
                            } else {
                                // TODO: 진행중/완료 시 화면 이동 처리 예정
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .alert("잠긴 퀘스트입니다", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) {}
        }
    }
}

// MARK: - 하위 퀘스트 카드 컴포넌트
struct SubQuestCard: View {
    let subQuest: SubQuest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80) // 상단 여백 (140-60)

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

                // 상단 이미지 (필요 시 배치 가능)
                VStack {
                    Spacer()
                }
                .frame(height: 80)
            }
            .frame(width: 355, height: 140)
            .background(Color(hex: backgroundColorHex))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
// MARK: - 미리보기

struct ChapterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChapterDetailView()
    }
}
