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

#if canImport(FirebaseFirestoreSwift)
import FirebaseFirestoreSwift
#endif

private enum BuildEnv {
    static let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - UI 상태
    @Published var isSignedIn: Bool = false
    @Published var currentUserEmail: String? = nil
    @Published var authError: String? = nil

    // Firestore 프로필 (UI에서 바인딩 가능)
    @Published var userProfile: UserProfile? = nil

    #if canImport(FirebaseAuth)
    private var authListener: AuthStateDidChangeListenerHandle?
    #endif

    // Firestore 핸들(옵셔널)
    #if canImport(FirebaseFirestore)
    private var db: Firestore? {
        guard FirebaseApp.app() != nil else { return nil }
        return Firestore.firestore()
    }
    #endif

    // MARK: - Init / Deinit
    init() {
        #if canImport(FirebaseAuth)
        // 프리뷰/미초기화 상황에서는 Firebase 접근 없음
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
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let uid = result.user.uid

            // 문서 없으면 생성(콘솔에서 잘못 만든 케이스 포함)
            await ensureUserDocumentExists(uid: uid, email: email)

            // 마지막 로그인 시간 갱신
            await updateLastLogin(uid: uid)

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

    // MARK: - 비밀번호 재설정 메일 전송
    func resetPassword(email: String) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        authError = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
        #else
        // Firebase 미사용 빌드일 경우: 필요 시 noop 처리
        authError = nil
        #endif
    }

    // MARK: - 회원가입 (+ Firestore 프로필 최소 생성)
    func signUp(email: String, password: String, nickname: String? = nil) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        authError = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            let nick = (nickname?.isEmpty == false) ? nickname! : "코블러"

            // ✅ 프로필 문서 생성 (exp/level은 클라이언트에서 쓰지 않음)
            try await createUserDocument(uid: uid, email: email, nickname: nick)

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
                    // FirebaseFirestoreSwift 사용: Timestamp → Date 디코딩
                    let profile = try snap.data(as: UserProfile.self)
                    self.userProfile = profile
                } catch {
                    self.authError = error.localizedDescription
                }
            } else {
                // 문서가 없으면 최소 문서 생성 후 다시 로드
                #if canImport(FirebaseAuth)
                let email = Auth.auth().currentUser?.email ?? ""
                Task {
                    try? await self.createUserDocument(uid: uid, email: email, nickname: "코블러")
                    self.fetchProfile(uid: uid)
                }
                #endif
            }
        }
        #endif
    }

    /// 클라이언트에서 안전하게 생성할 수 있는 최소 프로필 (exp/level 제외)
    private func createUserDocument(uid: String, email: String, nickname: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db else { return }
        let data: [String: Any] = [
            "nickname": nickname,
            "email": email,
            "profileImageURL": NSNull(),
            "createdAt": FieldValue.serverTimestamp(),
            "character": [
                "stage": "egg",
                "customization": [:] as [String: String]
            ],
            "settings": [
                "notificationsEnabled": true,
                "darkMode": false
            ],
            "lastLogin": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(uid).setData(data, merge: true)
        #endif
    }

    /// 로그인 성공 시 마지막 접속 시간 업데이트
    private func updateLastLogin(uid: String) async {
        #if canImport(FirebaseFirestore)
        guard let db else { return }
        do {
            try await db.collection("users").document(uid)
                .setData(["lastLogin": FieldValue.serverTimestamp()], merge: true)
        } catch {
            self.authError = error.localizedDescription
        }
        #endif
    }

    /// 첫 로그인/마이그레이션 대비: 문서가 없으면 생성
    private func ensureUserDocumentExists(uid: String, email: String) async {
        #if canImport(FirebaseFirestore)
        guard let db else { return }
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            if !snap.exists {
                let nick = email.split(separator: "@").first.map(String.init) ?? "코블러"
                try await createUserDocument(uid: uid, email: email, nickname: nick)
            }
        } catch {
            self.authError = error.localizedDescription
        }
        #endif
    }

    // MARK: - 개발 편의용(디버그 로그인)
    func debugSignIn() {
        isSignedIn = true
        currentUserEmail = "debug@cobling.app"
        userProfile = UserProfile(
            id: "debug",
            nickname: "디버그유저",
            email: "debug@cobling.app",
            level: nil,
            exp: nil,
            profileImageURL: nil,
            createdAt: Date(),
            character: .init(stage: "egg", customization: [:]),
            settings: .init(notificationsEnabled: true, darkMode: false),
            lastLogin: Date()
        )
    }
}

// MARK: - UserProfile 모델 (DB 스키마에 맞춤)
struct UserCharacter: Codable {
    var stage: String               // "egg" | "baby" | "grown"
    var customization: [String: String]?
}

struct UserSettings: Codable {
    var notificationsEnabled: Bool
    var darkMode: Bool
}

struct UserProfile: Codable, Identifiable {
    var id: String                  // Firebase Auth UID (문서 ID)
    var nickname: String
    var email: String
    // exp/level은 서버(Functions) 전용 → 클라에서 nil 가능성 고려
    var level: Int?
    var exp: Int?
    var profileImageURL: String?
    var createdAt: Date             // 서버타임스탬프를 읽어 디코딩
    var character: UserCharacter
    var settings: UserSettings
    var lastLogin: Date?

    static func new(uid: String, email: String, nickname: String) -> UserProfile {
        UserProfile(
            id: uid,
            nickname: nickname,
            email: email,
            level: nil,
            exp: nil,
            profileImageURL: nil,
            createdAt: Date(),
            character: .init(stage: "egg", customization: [:]),
            settings: .init(notificationsEnabled: true, darkMode: false),
            lastLogin: nil
        )
    }
}
