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
    @EnvironmentObject var authVM: AuthViewModel
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var isHintOn = false
    @State private var isStoryOn = false
    
    // DB stage → 에셋 prefix (게임 캐릭터용)
    private var gameCharacterAssetPrefix: String {
        let stage = (authVM.userProfile?.character.stage ?? "egg")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let allowed: Set<String> = ["egg", "kid", "cobling", "legend"]
        let safeStage = allowed.contains(stage) ? stage : "egg"

        return "cobling_stage_\(safeStage)"
    }
    
    // 방향 → suffix 매핑
    // up    -> back
    // down  -> front
    // left  -> left
    // right -> right
    private var directionSuffix: String {
        switch viewModel.characterDirection {
        case .up: return "back"
        case .down: return "front"
        case .left: return "left"
        case .right: return "right"
        }
    }
    
    // 최종 캐릭터 에셋 이름
    // ex) "cobling_stage_kid_front"
    private var gameCharacterDirectionalAssetName: String {
        "\(gameCharacterAssetPrefix)_\(directionSuffix)"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {

            // MARK: - Background
            Color(hex: "#FFF2DC")
                .ignoresSafeArea()
            
            VStack(spacing: 4) {
                // 상단 노치	
                Spacer().frame(height: 42)

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
                        appState.isInGame = false
                        dismiss()
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
                    let tileSize: CGFloat = 36
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

                        Image(gameCharacterDirectionalAssetName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: tileSize * 1.4,
                                height: tileSize * 1.4
                            )
                            .position(x: x, y: y - 15)
                            // 방향이 바뀔 때 자연스럽게 교체
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.12), value: viewModel.characterDirection)
                    }
                    .frame(
                        width: CGFloat(map.first?.count ?? 0) * tileSize,
                        height: CGFloat(map.count) * tileSize
                    )
                }
                .padding(.top, 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
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
    }
}
