// GameMapView.swift
// 디자인 기반 재사용 가능한 맵 뷰

// GameMapView.swift

import SwiftUI

struct GameMapView: View {
    @ObservedObject var viewModel: QuestViewModel
    var questTitle: String

    @State private var isHintOn = false
    @State private var isStoryOn = false
    @State private var goBackToQuestList = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 배경 색
            Color(hex: "#FFF2DC")
                .ignoresSafeArea()

            // 본문 내용
            VStack(spacing: 8) {
                Spacer().frame(height: 48)

                // 퀘스트 제목
                HStack {
                    Spacer()
                    Text(questTitle)
                        .font(.gmarketBold34)
                        .foregroundColor(Color(hex: "#3A3A3A"))
                        .padding(.top, 12)
                    Spacer()
                }
                .padding(.top, 16)

                // 상단 버튼
                HStack {
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.startExecution()
                        }) {
                            Image("gp_play")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }

                        Button(action: {
                            withAnimation {
                                isHintOn.toggle()
                            }
                        }) {
                            Image(isHintOn ? "gp_hint_on" : "gp_hint_off")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.leading, 40) // ✅ 버튼 묶음 전체에만 패딩 적용
                    .zIndex(1)

                    Spacer()

                    // 나가기 버튼
                    Button(action: {
                        goBackToQuestList = true
                    }) {
                        Image("gp_out")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 40)
                    .padding(.top, 10)
                }

                // 맵 영역
                ZStack {
                    let tileSize: CGFloat = 40
                    let map = viewModel.mapData

                    VStack(spacing: 0) {
                        ForEach(map.indices, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(map[row].indices, id: \.self) { col in
                                    ZStack {
                                        if map[row][col] == 1 || map[row][col] == 2 {
                                            Image("iv_game_way_1")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: tileSize, height: tileSize)
                                        }

                                        if map[row][col] == 2 {
                                            Image("gp_flag")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 36, height: 36)
                                                .offset(y: -15)
                                        }
                                    }
                                    .frame(width: tileSize, height: tileSize)
                                }
                            }
                        }
                    }

                    // 캐릭터
                    GeometryReader { geo in
                        let characterX = CGFloat(viewModel.characterPosition.col) * tileSize + tileSize / 2
                        let characterY = CGFloat(viewModel.characterPosition.row) * tileSize + tileSize / 2

                        Image("cobling_character_super")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tileSize * 1.4, height: tileSize * 1.4)
                            .position(x: characterX, y: characterY - 15)
                    }
                    .frame(width: CGFloat(map[0].count) * tileSize,
                           height: CGFloat(map.count) * tileSize)
                }
                .padding(16)
            }

            // 스토리 말풍선 & 버튼
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 8) {
                    Spacer()

                    ZStack(alignment: .trailing) {
                        if isStoryOn {
                            SpeechBubbleView(message: "응응..?? 여기 어디지??\n앞에 뭐가 보여!\n나 앞으로 4칸 가야 해!")
                                .transition(.opacity)
                                .padding(.trailing, 50)
                        }

                        Button(action: {
                            withAnimation {
                                isStoryOn.toggle()
                            }
                        }) {
                            Image(isStoryOn ? "gp_story_btn_on" : "gp_story_btn_off")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 12)
            }

            // 힌트 말풍선을 ZStack 최상단에 별도로 위치
            if isHintOn {
                VStack {
                    Spacer().frame(height: 160) // 버튼 위치 아래로 조정
                    HStack {
                        Spacer().frame(width: 80) // 버튼 왼쪽 위치에 맞춤
                        SpeechBubbleView(message: "앞으로 가는 블록을 4번 써보세요! \n 앞으로가기와, 왼쪽으로 돌기를 조합해봐요 !")
                            .fixedSize()
                            .padding(.top, 8)
                            .zIndex(100)
                            .transition(.opacity)
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            NavigationLink(destination: QuestListView(), isActive: $goBackToQuestList) {
                EmptyView()
            }.hidden()
        }
    }
}

#Preview {
    let dummyViewModel = QuestViewModel()
    dummyViewModel.mapData = [
        [1, 1, 1, 1, 1, 1, 2],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 0, 0, 1],
        [1, 1, 1, 1, 1, 1, 1]
    ]
    dummyViewModel.characterPosition = (row: 4, col: 0)

    return GameMapView(viewModel: dummyViewModel, questTitle: "잠든 알의 속삭임")
}
