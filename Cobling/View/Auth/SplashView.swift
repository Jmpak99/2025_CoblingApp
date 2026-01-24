//
//  SplashView.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import SwiftUI

// 스플래시 화면 뷰 정의
struct SplashView: View {
    // 일정 시간이 지난 후 홈 화면으로 전환 여부 관리
    @State private var isActive = false

    var body: some View {
        // isActive가 true면 HomeView()로 이동
        if isActive {
            HomeView() // 홈 화면으로 이동
        } else {
            // 조건이 false일 때 Splash화면 구성
            ZStack {
                Color(hex: "#FFF7E9") // 배경색
                    .edgesIgnoringSafeArea(.all) // 안전 영역을 무시하고 전체 화면 채우기
                
                //컨텐츠 수직 정렬
                VStack(spacing: 16) {
                    Image("cobling_character_super")
                        .resizable() // 이미지 크기 변경 가능하도록
                        .scaledToFit() // 이미지 비율 유지하며 컨테이너에 맞게 조정
                        .frame(width: 178, height: 178)

                    Text("코블링")
                        .font(.leeseoyun48) //타이틀 폰트
                        .foregroundColor(Color(hex: "#3A3A3A")) // 타이틀 글자색

                    Text("모바일 블록코딩앱")
                        .font(.gmarketMedium18) // 서브타이틀 폰트
                        .foregroundColor(Color(hex: "#3A3A3A")) // 서브타이틀 글자색
                }
            }
            .onAppear {
                // 뷰가 화면에 나타날 때 실행되는 로직
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // 2초 후 isActive를 true로 설정하여 화면 전환
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
