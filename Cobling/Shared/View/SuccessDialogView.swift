//
//  SuccessDialogView.swift
//  Cobling
//
//  Created by 박종민 on 7/29/25.
//

import SwiftUI

struct SuccessDialogView: View {
    var onRetry: () -> Void
    var onNext: () -> Void

    var body: some View {
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 다이얼로그 박스
                VStack(spacing: 16) {
                    Text("우와! 정말 잘했어 !!")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("코블링이 성장했어 !")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button(action: onRetry) {
                            Text("다시하기")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "EDEBE5"))
                                .cornerRadius(12)
                        }

                        Button(action: onNext) {
                            Text("다음 퀘스트로")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "FFD475"))
                                .cornerRadius(12)
                        }
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

struct SuccessDialogView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            SuccessDialogView(
                onRetry: { print("🔄 다시하기") },
                onNext: { print("➡️ 다음 퀘스트") }
            )
        }
    }
}
