// GameMapView.swift
// 디자인 기반 재사용 가능한 맵 뷰

import SwiftUI

struct GameMapView: View {
    let mapData: [[Int]]              // 0: 빈칸, 1: 길, 2: 깃발
    let characterPosition: (row: Int, col: Int)
    
    @State private var isHintOn = false
    @State private var isStoryOn = false

    var body: some View {
        ZStack (alignment: .topLeading) {
            // 배경
            Color(hex: "#FFF2DC")
                .ignoresSafeArea()
            
            VStack (spacing : 8) {
                Spacer().frame(height: 48)
                // MARK: - 상단 타이틀 + 버튼
                HStack (alignment: .center) {
                    Spacer()
                    Text("잠든 알의 속삭임")
                        .font(.gmarketBold34)
                        .foregroundColor(Color(hex: "#3A3A3A"))
                        .padding(.top, 12)
                    Spacer()
                }
                .padding(.top, 16)
                
                // MARK: - 플레이 & 힌트버튼
                HStack{
                    HStack(spacing : 12) {
                        Button(action : {
                            // 블록 실행 로직 연결 예정
                        }) {
                            Image("gp_play")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                        
                        Button(action : {
                            isHintOn.toggle( )
                        }) {
                            Image(isHintOn ? "gp_hint_on" : "gp_hint_off")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                    }
                    .padding(.leading, 40)
                    
                    Spacer()
                    
                    Button(action: {
                        // 나가기 액션
                    }) {
                        Image("gp_out")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .padding(.trailing, 40)
                    
                    .padding(.top, 10)
                    
                }
                
                
                // MARK: - 맵 타일 구성
                ZStack { // 맵 전체를 감싸는 ZStack
                    
                    // 1. 맵 전체 (타일 영역)
                    let tileSize: CGFloat = 40
                    let mapRows = mapData.count
                    let mapCols = mapData.first?.count ?? 0
                    let mapWidth = CGFloat(mapCols) * tileSize
                    let mapHeight = CGFloat(mapRows) * tileSize
                    
                    VStack(spacing: 0) { // 맵 전체 수직 정렬
                        ForEach(mapData.indices, id: \.self) { row in // 각 행 반복
                            HStack(spacing: 0) { // 한 행의 열을 수평 정렬
                                ForEach(mapData[row].indices, id: \.self) { col in // 각 열 반복
                                    ZStack { // 한 타일 내의 요소들을 겹쳐서 표시
                                        if mapData[row][col] == 1 || mapData[row][col] == 2 {
                                            Image("iv_game_way_1") // 길 타일 이미지
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40, height: 40) // 타일 크기
                                        }

                                        if mapData[row][col] == 2 {
                                            Image("gp_flag") // 깃발 이미지
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 36, height: 36) // 깃발 크기
                                                .offset(y: -15) // 약간 위로 띄움
                                        }
                                    }
                                    .frame(width: 40, height: 40) // 각 타일 뷰 크기 고정
                                }
                            }
                        }
                    }

                    // 캐릭터는 맵 위에 별도 위치로 그리기
                    // 3. 캐릭터 그리기
                    GeometryReader { geo in
                        let characterX = CGFloat(characterPosition.col) * tileSize + tileSize / 2
                        let characterY = CGFloat(characterPosition.row) * tileSize + tileSize / 2

                        Image("cobling_character_super")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tileSize * 1.4, height: tileSize * 1.4)
                            .position(x: characterX, y: characterY - 15)
                    }
                    // GeometryReader가 맵 영역을 벗어나지 않도록 크기 고정
                    .frame(width: mapWidth, height: mapHeight)

                }
                .padding(16) // 전체 맵 영역에 여백 추가
            }
            

            // MARK: - 스토리 버튼 (우측 하단)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isStoryOn.toggle()
                    }) {
                        Image(isStoryOn ? "gp_story_btn_on" : "gp_story_btn_off")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.trailing, 30)
            }
            .padding(12)
        }
    }
}

// MARK: - 예제 미리보기
#if DEBUG
struct GameMapView_Previews: PreviewProvider {
    static var previews: some View {
        GameMapView(
            mapData: [
                [1, 1, 1, 1, 1, 1, 2],
                [1, 0, 0, 0, 0, 0, 1],
                [1, 0, 0, 0, 0, 0, 1],
                [1, 0, 0, 0, 0, 0, 1],
                [1, 1, 1, 1, 1, 1, 1]
            ],
            characterPosition: (row: 4, col: 0)
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif
