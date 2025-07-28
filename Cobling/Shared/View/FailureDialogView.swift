//
//  FailureDialogView.swift
//  Cobling
//
//  Created by 박종민 on 7/29/25.
//

import SwiftUI

struct FailureDialogView: View {
    var onRetry: () -> Void  // 다시하기 버튼 눌렀을 때 실행할 액션

    var body: some View {
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 다이얼로그 카드
                VStack(spacing: 16) {
                    Text("앗, 다시 생각해볼까?")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("어려우면 힌트를 확인해봐")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        onRetry()
                    }) {
                        Text("다시하기")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FF9EC9"))
                            .cornerRadius(12)
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 40)
            }
        }
    }
}

struct FailureDialogView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            FailureDialogView {
                print("🔁 다시하기 눌림")
            }
        }
    }
}
