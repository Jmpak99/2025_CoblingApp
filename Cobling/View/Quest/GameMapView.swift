// GameMapView.swift
// 디자인 기반 재사용 가능한 맵 뷰

import SwiftUI
struct GameMapView: View {
    @ObservedObject var viewModel: QuestViewModel
    var questTitle: String
    
    
    @State private var isHintOn = false
    @State private var isStoryOn = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#FFF2DC")
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                Spacer().frame(height: 48)
                
                HStack {
                    Spacer()
                    Text(questTitle)
                        .font(.gmarketBold34)
                        .foregroundColor(Color(hex: "#3A3A3A"))
                        .padding(.top, 12)
                    Spacer()
                }
                .padding(.top, 16)
                
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
                            isHintOn.toggle()
                        }) {
                            Image(isHintOn ? "gp_hint_on" : "gp_hint_off")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.leading, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        // 나가기 처리
                    }) {
                        Image("gp_out")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 40)
                    .padding(.top, 10)
                }
                
                // MARK: - 맵 타일
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
                    
                    GeometryReader { geo in
                        let characterX = CGFloat(viewModel.characterPosition.col) * tileSize + tileSize / 2
                        let characterY = CGFloat(viewModel.characterPosition.row) * tileSize + tileSize / 2
                        
                        Image("cobling_character_super")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tileSize * 1.4, height: tileSize * 1.4)
                            .position(x: characterX, y: characterY - 15)
                    }
                    .frame(width: CGFloat(map[0].count) * tileSize, height: CGFloat(map.count) * tileSize)
                }
                .padding(16)
            }
            
            // MARK: - 말풍선과 버튼
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 8) {
                    Spacer()
                    
                    ZStack(alignment: .trailing) {
                        if isStoryOn {
                            SpeechBubbleView(message: "응응..?? 여기 어디지??\n앞에 뭐가 보여!\n나 앞으로 4칸 가야 해!")
                                .transition(.opacity)
                                .padding(.trailing, 50) // 버튼과의 간격 확보
                        }
                        
                        // 버튼은 항상 오른쪽 하단 고정
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
        }
    }
}



