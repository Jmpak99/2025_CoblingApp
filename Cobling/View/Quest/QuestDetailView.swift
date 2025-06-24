//
//  QuestDetailView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

// MARK: - 하위 퀘스트 상태

enum SubQuestState {
    case completed, inProgress, locked
}

// MARK: - 하위 퀘스트 데이터 모델

struct SubQuest: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let state: SubQuestState
}

// MARK: - QuestDetailView

struct QuestDetailView: View {
    let chapter: Quest  // 전달받은 챕터 정보
    @State private var showLockedAlert = false

    // 샘플 하위 퀘스트 리스트 (임시 하드코딩)
    private var subQuests: [SubQuest] {
        switch chapter.title {
        case "잠든 알의 속삭임":
            return [
                SubQuest(title: "1. 알 속의 꿈틀", description: "무언가 꿈틀거려요.", state: .completed),
                SubQuest(title: "2. 알 속의 소리", description: "알 속에서 소리가 나요.", state: .inProgress),
                SubQuest(title: "3. 아직 잠든 알", description: "깨어날 준비가 덜 됐어요.", state: .locked),
                SubQuest(title: "4. 온기의 기척", description: "따뜻함이 스며들어요.", state: .locked),
                SubQuest(title: "5. 깨지는 순간", description: "알이 흔들리고 있어요.", state: .locked)
            ]
        default:
            return [
                SubQuest(title: "공통 미션", description: "기본 미션입니다.", state: .inProgress)
            ]
        }
    }

    var body: some View {
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

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(subQuests) { quest in
                        SubQuestCard(subQuest: quest,
                                     backgroundColor: chapter.backgroundColor) {
                            if quest.state == .locked {
                                showLockedAlert = true
                            } else {
                                // TODO: 게임 화면으로 이동
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .alert("잠긴 퀘스트입니다", isPresented: $showLockedAlert) {
            Button("확인", role: .cancel) {}
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 하위 퀘스트 카드 컴포넌트

struct SubQuestCard: View {
    let subQuest: SubQuest
    let backgroundColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

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

                VStack {
                    Spacer()
                }
                .frame(height: 80)
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
        QuestDetailView(chapter: Quest(
            title: "잠든 알의 속삭임",
            subtitle: "깨어날 시간이에요, 코블링",
            status: .completed,
            backgroundColor: Color(hex: "#FFEEEF")
        ))
    }
}
