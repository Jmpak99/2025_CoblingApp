//
//  IfBlockView.swift
//  Cobling
//
//  Created by 박종민 on 1/23/26.
//

import SwiftUI

struct IfHeaderView: View {
    @ObservedObject var block: Block
    
    // 스테이지별 허용 조건 목록을 외부에서 주입
    let options: [IfCondition]
    
    // 허용 목록에 없으면 fallback(기본값)
    let defaultCondition: IfCondition


    var body: some View {
        HStack {
            HStack(spacing: 6) {
                
                Menu {
                    ForEach(options) { cond in
                        Button {
                            block.condition = cond
                        } label: {
                            Text(cond.label)
                                .font(.pretendardMedium14)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(block.condition.label)
                            .font(.pretendardMedium14)
                            .foregroundColor(.black)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background(Color.white)
                    .cornerRadius(6)
                }
                .padding(.leading, -12)

            }

            Spacer()

            ZStack {
                Circle().fill(Color.white)
                Image(systemName: "questionmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#4CCB7A"))
            }
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        
        // 현재 블록의 condition이 허용 목록 밖이면 자동 보정
        .onAppear {
            guard block.type == .if || block.type == .ifElse else { return }
            if !options.contains(block.condition) {
                block.condition = defaultCondition
            }
        }
    }
}
