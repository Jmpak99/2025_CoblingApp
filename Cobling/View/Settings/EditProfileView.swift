//
//  EditProfileView.swift
//  Cobling
//
//  Created by 박종민 on 8/5/25.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // 상단 바
            HStack(spacing: 8) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.pretendardMedium18)
                        .foregroundColor(.black)
                        .padding(.top, 2)
                }

                Text("내 정보 수정")
                    .font(.pretendardBold24)
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 30)

            // 프로필 이미지
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#E9E8DD"))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    )

                Text("개인")
                    .font(.pretendardMedium14)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#E9E8DD"))
                    .cornerRadius(6)
            }
            .padding(.bottom, 20)

            Divider()

            // 입력 필드
            VStack(spacing: 20) {
                LabeledTextField(label: "닉네임", placeholder: "이름을 입력하세요.", text: $nickname)
                LabeledTextField(label: "이메일", placeholder: "email@email.com", text: $email)
                LabeledTextField(label: "비밀번호", placeholder: "영어소문자, 숫자 포함 8자 이상", text: $password, isSecure: true)
                LabeledTextField(label: "비밀번호 확인", placeholder: "영어소문자, 숫자 포함 8자 이상", text: $confirmPassword, isSecure: true)
            }
            .padding(.top, 24)
            .padding(.horizontal)

            Spacer()

            // 완료 버튼
            Button(action: {
                // 저장 동작 처리
            }) {
                Text("완료")
                    .font(.pretendardBold18)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#E9E8DD"))
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Label + TextField 컴포넌트
struct LabeledTextField: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.pretendardMedium14)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EditProfileView()
    }
}
