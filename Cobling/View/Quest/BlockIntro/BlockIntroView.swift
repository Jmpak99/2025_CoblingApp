//
//  BlockIntroView.swift
//  Cobling
//
//  Created by 박종민 on 3/7/26.
//

import SwiftUI

// MARK: - 새롭게 소개할 블록 종류
enum BlockIntroType {
    case attack
    case repeatLoop
    case condition
}

// MARK: - 블록 소개 데이터 모델
struct BlockIntroContent {
    let title: String
    let subtitle: String
    let description: String
    let exampleTitle: String
    let exampleCaption: String
    let imageName: String
    let exampleImageName: String?
    let buttonTitle: String
}

// MARK: - BlockIntroType별 표시 내용 매핑
extension BlockIntroType {
    var content: BlockIntroContent {
        switch self {

        case .attack:
            return BlockIntroContent(
                title: "새로운 블록을 배웠어요!",
                subtitle: "공격 블록",
                description: "앞에 있는 적을 공격할 수 있어요.\n적이 길을 막고 있다면 공격 블록을 사용해보세요.",
                exampleTitle: "사용 예시",
                exampleCaption: "캐릭터 앞에 적이 있을 때 공격 블록을 실행하면 적을 물리칠 수 있어요.",
                imageName: "block_attack",
                exampleImageName: nil,
                buttonTitle: "시작하기"
            )

        case .repeatLoop:
            return BlockIntroContent(
                title: "새로운 블록을 배웠어요!",
                subtitle: "반복 블록",
                description: "같은 행동을 여러 번 반복할 수 있어요.\n똑같은 블록을 여러 번 놓지 않고도 더 쉽게 코드를 만들 수 있어요.",
                exampleTitle: "사용 예시",
                exampleCaption: "반복 횟수를 3으로 설정하면 앞으로 3칸 이동할 수 있어요.",
                imageName: "block_repeat_count",
                exampleImageName: "example_repeat_count",
                buttonTitle: "시작하기"
            )

        case .condition:
            return BlockIntroContent(
                title: "새로운 블록을 배웠어요!",
                subtitle: "조건 블록",
                description: "상황에 따라 다른 행동을 할 수 있어요.\n앞이 막혀 있는지, 적이 있는지 확인하고 알맞게 움직여보세요.",
                exampleTitle: "사용 예시",
                exampleCaption: "앞에 적이 있으면 공격하도록 만들 수 있어요.",
                imageName: "block_if",
                exampleImageName: "example_if",
                buttonTitle: "시작하기"
            )
        }
    }
}

// MARK: - 블록 소개 팝업 뷰
struct BlockIntroView: View {

    let type: BlockIntroType
    let onStart: () -> Void

    private var content: BlockIntroContent {
        type.content
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 28)

                Text(content.title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(Color(hex: "#2E3A2D"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 18)

                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(hex: "#F6F8EF"))
                        .frame(width: 170, height: 170)

                    Group {
                        if hasValidImageName(content.imageName) {
                            Image(content.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 110, height: 110)
                        } else {
                            Image(systemName: fallbackIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 62, height: 62)
                                .foregroundColor(Color(hex: "#6B8F5D"))
                        }
                    }
                }

                Spacer().frame(height: 22)

                Text(content.subtitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#2E3A2D"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 14)

                Text(content.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#4C5B48"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 28)

                Spacer().frame(height: 22)

                VStack(alignment: .leading, spacing: 12) {
                    Text(content.exampleTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#5A6E52"))

                    if let exampleImageName = content.exampleImageName,
                       hasValidImageName(exampleImageName) {
                        Image(exampleImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 70)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(content.exampleCaption)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#5F6B5A"))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(hex: "#FFF8E9"))
                )
                .padding(.horizontal, 22)

                Spacer().frame(height: 28)

                Button(action: onStart) {
                    Text(content.buttonTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: "#6B8F5D"))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 22)

                Spacer().frame(height: 24)
            }
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        }
    }
}

// MARK: - 내부 헬퍼
private extension BlockIntroView {
    var fallbackIconName: String {
        switch type {
        case .attack:
            return "burst.fill"
        case .repeatLoop:
            return "repeat"
        case .condition:
            return "questionmark.circle.fill"
        }
    }

    func hasValidImageName(_ name: String) -> Bool {
        UIImage(named: name) != nil
    }
}


// MARK: - Preview
#Preview("공격 블록") {
    BlockIntroView(type: .attack) {
        print("공격 블록 시작")
    }
}

#Preview("반복 블록") {
    BlockIntroView(type: .repeatLoop) {
        print("반복 블록 시작")
    }
}

#Preview("조건 블록") {
    BlockIntroView(type: .condition) {
        print("조건 블록 시작")
    }
}
