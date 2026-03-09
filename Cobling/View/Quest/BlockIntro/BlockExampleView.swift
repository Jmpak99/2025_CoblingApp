//
//  BlockExampleView.swift
//  Cobling
//
//  Created by 박종민 on 3/7/26.
//

import SwiftUI

struct BlockExampleView: View {
   let type: BlockIntroType

   var body: some View {
       switch type {
       case .attack:
           AttackBlockExampleSection()

       case .repeatLoop:
           RepeatBlockExampleSection()

       case .condition:
           ConditionBlockExampleSection()
           
       case .turnLeft:
           TurnLeftBlockExampleSection()

       case .turnRight:
           TurnRightBlockExampleSection()
       }
   }
}

// MARK: - 공격 예시
private struct AttackBlockExampleSection: View {
   var body: some View {
       HStack(spacing: 10) {
           Image("block_attack")
               .resizable()
               .scaledToFit()
               .frame(height: 34)

           Text("→")

           Text("적 공격")
               .font(.system(size: 13, weight: .semibold))
               .foregroundColor(Color(hex: "#5A6E52"))
       }
       .frame(maxWidth: .infinity, alignment: .leading)
   }
}

// MARK: - 반복 예시
private struct RepeatBlockExampleSection: View {
   var body: some View {
       VStack(alignment: .leading, spacing: 6) {
           Image("block_repeat_count")
               .resizable()
               .scaledToFit()
               .frame(height: 34)

           HStack(alignment: .top, spacing: 8) {
               Rectangle()
                   .fill(Color(hex: "#CFCFC7"))
                   .frame(width: 3, height: 32)
                   .cornerRadius(2)
                   .padding(.leading, 10)

               Image("block_move")
                   .resizable()
                   .scaledToFit()
                   .frame(height: 30)
           }
       }
       .frame(maxWidth: .infinity, alignment: .leading)
   }
}

// MARK: - 조건 예시
private struct ConditionBlockExampleSection: View {
   var body: some View {
       VStack(alignment: .leading, spacing: 6) {
           Image("block_if")
               .resizable()
               .scaledToFit()
               .frame(height: 34)

           HStack(alignment: .top, spacing: 8) {
               Rectangle()
                   .fill(Color(hex: "#CFCFC7"))
                   .frame(width: 3, height: 32)
                   .cornerRadius(2)
                   .padding(.leading, 10)

               Image("block_attack")
                   .resizable()
                   .scaledToFit()
                   .frame(height: 30)
           }
       }
       .frame(maxWidth: .infinity, alignment: .leading)
   }
}

// MARK: - 왼쪽으로 돌기 예시
private struct TurnLeftBlockExampleSection: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("block_turn_left")
                .resizable()
                .scaledToFit()
                .frame(height: 34)

            Text("→")

            Text("왼쪽으로 방향 전환")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#5A6E52"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 오른쪽으로 돌기 예시
private struct TurnRightBlockExampleSection: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("block_turn_right")
                .resizable()
                .scaledToFit()
                .frame(height: 34)

            Text("→")

            Text("오른쪽으로 방향 전환")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "#5A6E52"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
