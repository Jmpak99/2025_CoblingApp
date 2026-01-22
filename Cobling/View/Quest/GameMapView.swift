//
//  GameMapView.swift
//  Cobling
//
//  Created by 박종민 on 2025/07/02.
//

import SwiftUI

struct GameMapView: View {
    @ObservedObject var viewModel: QuestViewModel
    var questTitle: String

    @EnvironmentObject var tabBarViewModel: TabBarViewModel

    @State private var isHintOn = false
    @State private var isStoryOn = false
    @State private var goBackToQuestList = false

    var body: some View {
        ZStack(alignment: .topLeading) {

            // MARK: - Background
            Color(hex: "#FFF2DC")
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Spacer().frame(height: 48)

                // MARK: - 타이틀
                HStack {
                    Spacer()
                    Text(questTitle)
                        .font(.gmarketBold34)
                        .foregroundColor(Color(hex: "#3A3A3A"))
                        .padding(.top, 12)
                    Spacer()
                }
                .padding(.top, 16)

                // MARK: - 상단 버튼 영역
                HStack {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.startExecution()
                        } label: {
                            Image("gp_play")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }

                        Button {
                            withAnimation {
                                isHintOn.toggle()
                            }
                        } label: {
                            Image(isHintOn ? "gp_hint_on" : "gp_hint_off")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.leading, 40)

                    Spacer()

                    Button {
                        goBackToQuestList = true
                    } label: {
                        Image("gp_out")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 40)
                    .padding(.top, 10)
                }

                // MARK: - Game Map
                ZStack {
                    let tileSize: CGFloat = 40
                    let map = viewModel.mapData

                    // 맵 타일
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

                                        // 적
                                        if viewModel.enemies.contains(where: {
                                            $0.row == row && $0.col == col
                                        }) {
                                            Image("cobling_character_enemies")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(
                                                    width: tileSize * 1.4,
                                                    height: tileSize * 1.4
                                                )
                                                .offset(y: -8)
                                        }

                                        // 깃발
                                        if viewModel.goalPosition.row == row &&
                                            viewModel.goalPosition.col == col {
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
                    GeometryReader { _ in
                        let x = CGFloat(viewModel.characterPosition.col) * tileSize + tileSize / 2
                        let y = CGFloat(viewModel.characterPosition.row) * tileSize + tileSize / 2

                        Image("cobling_character_super")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: tileSize * 1.4,
                                height: tileSize * 1.4
                            )
                            .position(x: x, y: y - 15)
                    }
                    .frame(
                        width: CGFloat(map.first?.count ?? 0) * tileSize,
                        height: CGFloat(map.count) * tileSize
                    )
                }
                .padding(16)
            }

            // MARK: - 스토리 말풍선
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 8) {
                    Spacer()

                    ZStack(alignment: .trailing) {
                        if isStoryOn,
                            let message = viewModel.storyMessage {
                                SpeechBubbleView(message: message)
                                    .transition(.opacity)
                                    .padding(.trailing, 50)
                        }
                        
                        Button {
                            withAnimation {
                                isStoryOn.toggle()
                            }
                        } label: {
                            Image(isStoryOn ? "gp_story_btn_on" : "gp_story_btn_off")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.trailing, 30)
                }
                .padding(.bottom, 12)
            }

            // MARK: - 힌트 말풍선
            if isHintOn,
               let message = viewModel.hintMessage {
                VStack {
                    Spacer().frame(height: 160)
                    HStack {
                        Spacer().frame(width: 80)
                        SpeechBubbleView(message: message)
                            .fixedSize()
                            .padding(.top, 8)
                            .transition(.opacity)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .navigationDestination(isPresented: $goBackToQuestList) {
            QuestListView()
                .onAppear {
                    tabBarViewModel.isTabBarVisible = true
                }
        }
    }
}
