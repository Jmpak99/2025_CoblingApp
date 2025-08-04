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

    // MARK: - Validation 상태
    private var isPasswordMismatch: Bool {
        !confirmPassword.isEmpty && password != confirmPassword
    }

    private var isPasswordValid: Bool {
        let regex = "^(?=.*[a-z])(?=.*\\d)[a-z\\d]{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password)
    }

    private var isFormValid: Bool {
        !nickname.isEmpty &&
        !email.isEmpty &&
        isPasswordValid &&
        password == confirmPassword
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 바
            HStack(spacing: 8) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
                
                Text("내 정보 수정")
                    .font(.pretendardBold34)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 18)

            
            ScrollView {
                VStack(spacing: 24) {
                    // 프로필 이미지
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 96, height: 96)
                            .overlay(Image(systemName: "photo")
                                        .font(.system(size: 30))
                                        .foregroundColor(.gray))
                        Text("개인")
                            .font(.pretendardMedium14)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#E9E8DD"))
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    
                    Group {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("닉네임")
                                .font(.pretendardBold14)
                            TextField("이름을 입력하세요.", text: $nickname)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("이메일")
                                .font(.pretendardBold14)
                            TextField("이메일을 입력하세요", text: $email)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("비밀번호")
                                .font(.pretendardBold14)
                            SecureField("영어소문자, 숫자 포함 8자 이상", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                            
                            if !password.isEmpty && !isPasswordValid {
                                Text("영어 소문자와 숫자를 포함해 8자 이상 입력해주세요.")
                                    .foregroundColor(.red)
                                    .font(.pretendardMedium14)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("비밀번호 확인")
                                .font(.pretendardBold14)
                            SecureField("비밀번호를 다시 입력하세요", text: $confirmPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.4)))
                            
                            if isPasswordMismatch {
                                Text("비밀번호가 일치하지 않습니다.")
                                    .foregroundColor(.red)
                                    .font(.pretendardMedium14)
                            }
                        }
                    }
                    
                    // 완료 버튼
                    Button(action: {
                        print("완료 버튼 눌림")
                    }) {
                        Text("완료")
                            .foregroundColor(.black)
                            .font(.pretendardBold18)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color(hex: "#E9E8DD") : Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EditProfileView()
    }
}
