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

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

private enum BuildEnv {
    static let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

@MainActor
final class AuthViewModel: ObservableObject {
    // UI 바인딩 상태
    @Published var isSignedIn: Bool = false
    @Published var currentUserEmail: String? = nil
    @Published var authError: String? = nil

    // Firestore 프로필(선택적으로 바인딩하여 UI 사용할 수 있음)
    @Published var userProfile: UserProfile? = nil

    #if canImport(FirebaseAuth)
    private var authListener: AuthStateDidChangeListenerHandle?
    #endif

    // Firestore 핸들(없을 수도 있으니 옵셔널)
    #if canImport(FirebaseFirestore)
    private var db: Firestore? {
        guard FirebaseApp.app() != nil else { return nil }
        return Firestore.firestore()
    }
    #endif

    init() {
        // 프리뷰/미초기화 상황에서는 Firebase에 접근하지 않음
        #if canImport(FirebaseAuth)
        guard !BuildEnv.isPreview, FirebaseApp.app() != nil else {
            self.isSignedIn = false
            self.currentUserEmail = nil
            return
        }

        // ✅ Auth 상태 리스너: 앱 재시작/로그인/로그아웃 시점마다 상태 반영
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isSignedIn = (user != nil)
            self.currentUserEmail = user?.email

            if let uid = user?.uid {
                self.fetchProfile(uid: uid) // 로그인되면 프로필 로드(없으면 자동 생성)
            } else {
                self.userProfile = nil
            }
        }
        #endif
    }

    deinit {
        #if canImport(FirebaseAuth)
        if let authListener { Auth.auth().removeStateDidChangeListener(authListener) }
        #endif
    }

    // MARK: - 로그인
    func signIn(email: String, password: String) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        authError = nil
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            // 상태는 리스너에서 갱신
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
        #else
        // Firebase 미사용 빌드 대비(개발용)
        self.isSignedIn = true
        self.currentUserEmail = email
        #endif
    }

    // MARK: - 회원가입 (+ Firestore 프로필 저장)
    func signUp(email: String, password: String, nickname: String? = nil) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        authError = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            let nick = (nickname?.isEmpty == false) ? nickname! : "코블러"

            // 프로필 문서 생성/병합 저장
            let profile = UserProfile.new(uid: uid, email: email, nickname: nick)
            try await saveProfile(profile: profile)
            // 상태는 리스너에서 갱신
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
        #else
        // Firebase 미사용 빌드 대비(개발용)
        self.isSignedIn = true
        self.currentUserEmail = email
        #endif
    }

    // MARK: - 로그아웃
    func signOut() {
        #if canImport(FirebaseAuth)
        if FirebaseApp.app() != nil {
            try? Auth.auth().signOut()
        }
        #endif
        self.isSignedIn = false
        self.currentUserEmail = nil
        self.userProfile = nil
    }

    // MARK: - Firestore I/O
    private func fetchProfile(uid: String) {
        #if canImport(FirebaseFirestore)
        guard let db else { return }
        db.collection("users").document(uid).getDocument { [weak self] snap, err in
            guard let self else { return }
            if let err = err {
                self.authError = err.localizedDescription
                return
            }
            if let snap, snap.exists {
                do {
                    let profile = try snap.data(as: UserProfile.self)
                    self.userProfile = profile
                } catch {
                    self.authError = error.localizedDescription
                }
            } else {
                // 문서가 없는 계정(이메일만 존재)일 경우 최소 프로필 생성
                #if canImport(FirebaseAuth)
                let email = Auth.auth().currentUser?.email ?? ""
                let profile = UserProfile.new(uid: uid, email: email, nickname: "코블러")
                Task { try? await self.saveProfile(profile: profile) }
                #endif
            }
        }
        #endif
    }

    private func saveProfile(profile: UserProfile) async throws {
        #if canImport(FirebaseFirestore)
        guard let db else { return }
        do {
            try db.collection("users").document(profile.id)
                .setData(from: profile, merge: true)
            self.userProfile = profile
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
        #endif
    }

    // MARK: - 개발 편의용(디버그 로그인)
    func debugSignIn() {
        isSignedIn = true
        currentUserEmail = "debug@cobling.app"
        userProfile = UserProfile.new(uid: "debug", email: "debug@cobling.app", nickname: "디버그유저")
    }
}

// MARK: - UserProfile 모델 (원하면 별도 파일로 분리)
struct UserProfile: Codable, Identifiable {
    var id: String            // Firebase Auth UID
    var nickname: String
    var email: String
    var level: Int
    var exp: Int
    var createdAt: Date
    var profileImageURL: String?

    static func new(uid: String, email: String, nickname: String) -> UserProfile {
        UserProfile(
            id: uid,
            nickname: nickname,
            email: email,
            level: 1,
            exp: 0,
            createdAt: Date(),
            profileImageURL: nil
        )
    }
}
