//
//  QuestListView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

// MARK: - Quest Data Model

// 하나의 퀘스트를 표현하는 데이터 구조체
struct Quest: Identifiable {
    let id = UUID() // 각 퀘스트의 고유 ID
    let title: String // 퀘스트 타이틀
    let subtitle: String // 퀘스트 서브타이틀
    let status: QuestStatus // 퀘스트 상태 (완료, 진행중, 잠김)
    let backgroundColor: Color // 퀘스트 카드 배경색
}

// 퀘스트 상태를 나타내는 열거형
enum QuestStatus {
    case completed, inProgress, locked // 완료 , 진행중, 잠김 세 가지 상태
    
    // 상태에 따라 해당하는 아이콘 이름 반환
    var iconName: String {
        switch self {
        case .completed: return "icon_completed" // 완료 아이콘
        case .inProgress: return "icon_inProgress" // 진행중 아이콘
        case .locked: return "icon_lock" // 잠김 아이콘
        }
    }
    
    // 상태에 따라 표시할 텍스트를 반환
    var labelText: String {
        switch self {
        case .completed: return "완료" // 완료 텍스트
        case .inProgress: return "진행중" // 진행중 텍스트
        case .locked: return "잠김" // 잠김 텍스트
        }
    }
}

// MARK: - Quest List View
// 퀘스트 리스트 화면 (전체 퀘스트 목록을 보여주는 메인 뷰)
struct QuestListView: View {
    @State private var showLockedAlert = false // 잠긴 퀘스트 클릭 시 알림창 표시 여부를 제어하는 상태 변수
    
    // 임시 퀘스트 데이터 배열 (하드코딩)
    let quests: [Quest] = [
        Quest(title: "잠든 알의 속삭임", //퀘스트 제목
              subtitle: "깨어날 시간이에요, 코블링", // 퀘스트 서브타이틀
              status: .completed, // 상태 : 진행중
              backgroundColor: Color(hex: "#FFEEEF")), // 배경색
        
        Quest(title: "코블링의 첫 걸음", // 퀘스트 제목
              subtitle: "한 걸음씩, 함께 나아가요", // 퀘스트 서브타이틀
              status: .inProgress, // 상태 : 잠김
              backgroundColor: Color(hex: "#FFF1DB")), // 배경색
        
        Quest(title: "반복의 언덕", // 퀘스트 제목
              subtitle: "같은 길도, 다르게 걸어볼까?", // 퀘스트 서브타이틀
              status: .locked, // 상태 : 잠김
              backgroundColor: Color(hex: "E3EDFB")), // 배경색
        
        Quest(title: "조건의 문", // 퀘스트 제목
              subtitle: "문을 여는 열쇠는 블록 안에 있어요", // 퀘스트 서브타이틀
              status: .locked, // 상태 : 잠김
              backgroundColor: Color(hex: "FFEEEF")),
        
        
    ]
    
    var body: some View {
        NavigationView { // 네비게이션 뷰로 화면 감싸기 (타이틀 + 네비게이션 지원)
            VStack(alignment: .leading, spacing: 0) { // 수직으로 뷰 쌓기, 왼쪽 정렬, 뷰 사이 간격 없음
                //상단 고정 타이틀
                Text("퀘스트")
                    .font(.pretendardBold34) // 폰트
                    .padding(.horizontal) // 좌우 여백 추가
                    .padding(.top, 20) // 상단 여백 20 추가
                
                ScrollView { // 수직 스크롤 가능한 뷰
                    VStack(spacing: 20) { // 카드 간 간격 20
                        ForEach(quests) { quest in // 각 퀘스트를 순회하며 카드 생성
                            QuestCardView(quest: quest) { // 카트 탭 시 액션
                                if quest.status == .locked {
                                    showLockedAlert = true // 잠긴 퀘스트 클릭 시 알림창 표시
                                } else {
                                    // 퀘스트 상세화면으로 이동 (추후 구현)
                                }
                            }
                        }
                    }
                    .padding() // VStack 전체 여백
                }
            }
            .alert(isPresented: $showLockedAlert) { //알림창 표시 조건
                Alert(title: Text("잠긴 퀘스트입니다")) //잠긴 퀘스트 알림 내용
            }
        }
    }
}

// MARK: - Quest Card View
// 개별 퀘스트 카드 뷰 정의
struct QuestCardView: View {
    let quest: Quest // 퀘스트 데이터 전달
    let onTap: () -> Void // 카드 클릭 시 수행할 동작

    var body: some View {
        Button(action: onTap) { // 카드 전체를 버튼으로 만들어 탭 가능하게 함
            ZStack { // 겹쳐서 배치할 뷰 구조 (상단 이미지 + 하단 테스트)
                VStack(spacing: 0) { // 상단 이미지 영역 + 하단 텍스트박스 수직 배치
                    Spacer()
                        .frame(height: 125) // 상단 이미지 영역 높이

                    ZStack {
                        // 하단 텍스트 배경
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white) // 흰 배경
                            .frame(height: 95) // 하단 영역 높이

                        HStack {
                            // 텍스트 영역 (타이틀 + 서브타이틀)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quest.title) // 퀘스트 제목
                                    .font(.gmarketBold16) // 제목 폰트
                                    .foregroundColor(.black) // 글자색
                                Text(quest.subtitle) // 서브타이틀
                                    .font(.pretendardRegular14) // 서브타이틀 폰트
                                    .foregroundColor(.gray) // 서브타이틀 글자색
                            }

                            Spacer() // 텍스트와 아이콘 사이 공간 확보

                            // 상태 아이콘 (완료, 잠김, 진행중)
                            Image(quest.status.iconName)
                                .resizable() // 크기 조절 가능
                                .frame(width: quest.status == .inProgress ? 83 : 70, // 상태에 따라 너비 조정
                                       height: 30) // 고정 높이 30
                        }
                        .padding(.horizontal, 16) //좌우 여백 16
                    }
                }

                // 상단 대표 이미지
                VStack {
                    HStack {
                        Spacer()
                        // 필요 시 우측 상단 아이콘 등 추가 가능
                    }
                    Spacer()
                }
                .frame(height: 125) // 상단 이미지 영역 크기와 동일
            }
            .frame(width: 335, height: 220) // 카드 전체 크기
            .background(quest.backgroundColor) // 카드 배경색
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous)) // 카드 외각 라운딩 처리
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4) // 그림자 효과
        }
        .buttonStyle(PlainButtonStyle()) // 버튼의 기본 효과 제거
    }
}

// MARK: - Preview
struct QuestListView_Previews: PreviewProvider {
    static var previews: some View {
        QuestListView()
    }
}

