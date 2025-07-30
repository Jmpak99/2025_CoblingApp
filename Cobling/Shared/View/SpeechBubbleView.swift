//
//  SpeechBubbleView.swift
//  Cobling
//
//  Created by 박종민 on 7/30/25.
//

import SwiftUI

struct SpeechBubbleView: View {
    var title: String = "코블링의 메시지"
    var message: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                // 타이틀 (아이콘 + 텍스트)
                HStack(alignment: .center, spacing: 8) {
                    Image("cobling_character_egg")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)
                }

                // 본문 메시지
                Text(message)
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: 250, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.black, lineWidth: 1)
                    .background(Color.white.cornerRadius(20))
            )
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        SpeechBubbleView(message: "으응..?? 여기 어디지??\n앞에 뭐가 보여!\n나 앞으로 4칸 가야 해!")
    }
}
