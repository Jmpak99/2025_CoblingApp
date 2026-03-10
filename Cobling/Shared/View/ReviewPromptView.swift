//
//  ReviewPromptView.swift
//  Cobling
//
//  Created by 박종민 on 3/10/26.
//

import SwiftUI

struct ReviewPromptView: View {
    let milestone: Int
    let onNegative: () -> Void
    let onPositive: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(headerEmoji)
                    .font(.system(size: 18))
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                Text(titleText)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true) // 텍스트가 잘리지 않도록 세로 확장
                    .padding(.horizontal, 16)

                Text(subtitleText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true) // 설명 텍스트 줄바꿈/세로 확장 처리
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                HStack(spacing: 10) {
                    Button(action: onNegative) {
                        Text("별로에요")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onPositive) {
                        Text("좋았어요")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18) // Spacer 제거 후 버튼과 텍스트 간격을 padding으로 조절
                .padding(.bottom, 16)
            }
            .frame(width: 270) // 카드 크기를 고정해서 작은 팝업 형태 유지
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.09, green: 0.11, blue: 0.18),
                                Color(red: 0.07, green: 0.08, blue: 0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Text
private extension ReviewPromptView {
    var headerEmoji: String {
        switch milestone {
        case 5:
            return "🌱"
        case 15:
            return "🎉"
        case 30:
            return "🏆"
        default:
            return "✨"
        }
    }

    var titleText: String {
        switch milestone {
        case 5:
            return "코블링과 첫 5개의 서브퀘스트를\n완료했어요!"
        case 15:
            return "코블링과 15개의 서브퀘스트를\n완료했어요!"
        case 30:
            return "코블링과 30개의 서브퀘스트를\n완료했어요!"
        default:
            return "코블링을 재미있게 사용하고 계신가요?"
        }
    }

    var subtitleText: String {
        switch milestone {
        case 5:
            return "써보니 어떠셨나요?"
        case 15:
            return "여기까지의 경험이 궁금해요."
        case 30:
            return "코블링이 마음에 드셨다면 응원 부탁드려요!"
        default:
            return "앱 사용 경험을 들려주세요."
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ReviewPromptView(
            milestone: 30,
            onNegative: {},
            onPositive: {}
        )
    }
}
