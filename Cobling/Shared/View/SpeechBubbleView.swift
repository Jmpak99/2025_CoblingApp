//
//  SpeechBubbleView.swift
//  Cobling
//
//  Created by 박종민 on 7/30/25.
//

import SwiftUI

struct SpeechBubbleView: View {
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image("spirit_forest") // 아이콘
                    .resizable()
                    .frame(width: 40, height: 40)

                Text("정령의 속삭임")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading) // 좌측 정렬
        }
        .padding(12)
        .frame(maxWidth: 250, alignment: .leading) // 💡 폭 제한 및 좌측 정렬
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}


#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        SpeechBubbleView(message: "으응..?? 여기 어디지??\n앞에 뭐가 보여!\n나 앞으로 4칸 가야 해!")
    }
}
