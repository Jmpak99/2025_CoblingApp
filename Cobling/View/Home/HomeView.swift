//
//  HomeView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

struct HomeView: View {
    // 사용자 레벨 하드코딩
    @State private var level = 1
    // 경험치 퍼센트 하드코딩 (0.0 ~ 1.0 사이 값으로 설정됨, 추후 퍼센트 변환됨)
    @State private var experience: Double = 0.5
    // 미션 완료 여부 하드코딩 (true면 체크됨)
    @EnvironmentObject var appState : AppState
    private let isMissionCompleted = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) { // 화면을 수직으로 정렬하며 각 요소 사이에 20pt 간격을 둠
                // MARK: - 상단 제목 (좌측 상단 "홈" 텍스트")
                HStack {
                    Text("홈")
                        .font(.pretendardBold34) // 폰트 크기 및 두께
                        .padding(.top, 16) // 상단 여백
                        .padding(.leading, 24) // 좌측 여백
                    Spacer() // 오른쪽 여백 확보
                }

                
                
                // MARK: - 인삿말 (중앙 정렬)
                VStack(spacing: 4) {
                    Text("반가워요") // 인삿말 첫 줄
                        .font(.leeseoyun24) // 텍스트 크기
                        .multilineTextAlignment(.center) // 가운데 정렬
                    Text("저는 코블링이에요!") // 인삿말 두번째 줄
                        .font(.leeseoyun24) // 텍스트 크기
                        .multilineTextAlignment(.center) // 가운데 정렬
                }
                .padding(.top, 48) // 인삿말 전체 위쪽에 48pt 여백 부여
                
                

                // MARK: - 캐릭터 이미지
                Image("cobling_character_egg") // 에셋에 추가한 파일 명
                    .resizable() // 크기 조절 가능하도록 설정
                    .scaledToFit() // 비율 유지하며 맞춤
                    .frame(width: 200, height: 200) // 이미지 크기 고정
                
                

                // MARK: - 키우러 가기 버튼 (중앙 정렬)
                Button(action: {
                    appState.selectedTab = .quest
                }) { // 버튼을 누르면 QuestListView로 이동
                    Text("키우러 가기") // 버튼 텍스트
                        .font(.pretendardRegular16) // 텍스트 폰트 설정
                        .foregroundColor(.black) // 텍스트 색상
                        .frame(width: 200, height: 50) // 버튼 크기 (200 * 50)
                        .background(Color(hex: "#E9E8DD")) // 배경색
                        .cornerRadius(12) // 모서리 둥글게
                        .padding(.horizontal, 40) // 좌우 여백
                }
                .padding(.top, 40) // 캐릭터 이미지와 간격 40pt

                
                
                // MARK: - 레벨 카드
                RoundedRectangle(cornerRadius: 24) // 모서리 둥근 배경카드 생성
                    .fill(Color(hex: "#F8F8F6")) // 색상
                    .frame(width: 335, height: 72) // 카드 크기
                    .overlay( // 카드 위에 내부 구성 요소 배치
                        VStack(alignment: .leading, spacing: 8) { // 세로방향 스택, 왼쪽정렬 + 각 항목당 8pt 간격
                            
                            //레벨 텍스트
                            Text("Lv. \(level)") // 현재 레벨 표시
                                .font(.gmarketMedium18) // 텍스트 크기, 굵기
                                .foregroundColor(Color(hex: "#1D260D")) // 텍스트 컬러
                            
                        
                            // 경험치 바와 퍼센트 텍스트를 수평 정렬
                            HStack { // 가로 방향으로 경험치 바와 퍼센트 텍스트 배치
                                let maxBarWidth: CGFloat = 230 // 경험치 바 최대 너비

                                ZStack(alignment: .leading) { // 배경 바와 채워진 바를 겹쳐서 왼쪽 기준 정렬
                                    //바 배경
                                    RoundedRectangle(cornerRadius: 20) // 경험치 바 형태
                                        .fill(Color(hex: "#E9E8DD")) // 경험치 바 배경
                                        .frame(width: 230, height: 16) // 경험치 바 전체 너비 고정
                                    
                                    //채워지는 바 배경
                                    RoundedRectangle(cornerRadius: 20) // 채워지는 바 형태
                                        .fill(Color(hex: "#EA4C89")) // 채워지는 바 배경
                                        .frame(width : maxBarWidth * experience, height: 16) // experience값에 따라 너비 동적으로 변경
                                }
                                
                                
                                Spacer() // 왼쪽과 오른쪽 텍스트 사이 최대 간격 확보 (우측 정렬)
                                
                                Text(String(format: "%.0f%%", experience * 100)) // 퍼센트 값 표시
                                    .font(.gmarketMedium16) // 텍스트 크기, 굵기
                                    .foregroundColor(Color(hex: "#1D260D")) // 텍스트 컬러
                            }
                        }
                        .padding(.horizontal, 20) // 카드 안쪽 좌우 여백 20pt
                        .padding(.vertical, 12) // 카드 안쪽 상하 여백 12pt
                    )
                    
                // 레벨 변경 표시
                    .onChange(of: experience) {
                        if experience >= 1.0 {
                            level += 1
                            experience = 0.0
                        }
                    }



                // MARK: - 오늘의 미션 카드
                RoundedRectangle(cornerRadius: 24) // 배경 카드 생성
                    .fill(Color(hex: isMissionCompleted ? "#FFECEC" : "#F8F8F6")) // 미션 완료 여부에 따라 배경색 변경
                    .frame(width: 335, height: 72) // 카드 크기
                    .overlay( // 카드 위에 내용 덮어쓰기
                        HStack(alignment: .center) { // 수평 정렬, 수직 기준은 중앙 정렬
                            
                            //좌측 아이콘 - SF Symbol에서 제공하는 물음표 아이콘
                            Image(systemName: "questionmark.circle") // SF Symbol 아이콘 사용
                                .resizable() // 크기 조절 가능하도록 설정
                                .frame(width: 24, height: 24) // 크기 설정
                                .foregroundColor(.gray) // 색상 회색으로

                            
                            // 가운데 텍스트 블록 (두 줄)
                            VStack(alignment: .leading, spacing: 2) { // 세로 정렬, 왼쪽 정렬, 요소 간 간격 2pt
                                Text("오늘의 미션") // 첫 번째 줄 텍스트
                                    .font(.gmarketMedium16) // 글자크기, 굵기
                                    .foregroundColor(.black) // 텍스트 색상
                                Text("두 문제 이상 풀기") // 두 번째 줄 텍스트
                                    .font(.pretendardRegular14) // 글자 크기
                                    .foregroundColor(.gray) // 텍스트 색상
                            }
                            .padding(.leading, 4) // 아이콘과 텍스트 사이 4pt여백 추가

                            Spacer() // 왼쪽 텍스트 블럭과 오른쪽 체크 아이콘 사이 벌림 (체크 아이콘 우측 정렬 용)

                            Image(systemName: isMissionCompleted ? "checkmark.square.fill" : "square") // isMissionCompleted가 true면 체크된 사각형 아이콘, false면 빈 사각형 아이콘 사용
                                .resizable() // 크기 조절 가능하도록
                                .frame(width: 24, height: 24) // 크기 설정
                                .foregroundColor(isMissionCompleted ? Color(hex: "#EA4C89") : .gray)
                        }
                        .padding(.horizontal, 20) // 카드 내부 좌우 여백을 20pt 부여
                    )
            
                Spacer() // 화면 아래 공간 확보, 모든 컨첸트 위로 올려서 위쪽 정렬되도록
            }
            .navigationBarHidden(true) // 기본으로 생성되는 네비게이션 바 숨김 처리
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}

