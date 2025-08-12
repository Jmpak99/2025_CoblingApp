//
//  AuthViewModel.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//


import Foundation
import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

private enum BuildEnv {
    static let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var currentUserEmail: String? = nil

    init() {
        // ✅ 프리뷰/미초기화 상황에서는 절대 Auth.auth()를 호출하지 않음
        #if canImport(FirebaseAuth)
        guard !BuildEnv.isPreview else {
            self.isSignedIn = false
            return
        }
        guard FirebaseApp.app() != nil else {
            self.isSignedIn = false
            return
        }
        self.isSignedIn = Auth.auth().currentUser != nil
        self.currentUserEmail = Auth.auth().currentUser?.email
        #else
        self.isSignedIn = false
        #endif
    }

    // 데모용 로그인 (Firebase 붙이기 전)
    func debugSignIn() {
        isSignedIn = true
        currentUserEmail = "debug@cobling.app"
    }

    func signOut() {
        #if canImport(FirebaseAuth)
        if FirebaseApp.app() != nil {
            try? Auth.auth().signOut()
        }
        #endif
        isSignedIn = false
        currentUserEmail = nil
    }

    // (선택) 실제 로그인/회원가입 붙일 때 사용
    func signIn(email: String, password: String) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
        self.isSignedIn = true
        self.currentUserEmail = email
        #else
        self.isSignedIn = true
        self.currentUserEmail = email
        #endif
    }

    func signUp(email: String, password: String) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
        self.isSignedIn = true
        self.currentUserEmail = email
        #else
        self.isSignedIn = true
        self.currentUserEmail = email
        #endif
    }
}
