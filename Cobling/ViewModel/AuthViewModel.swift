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
        // 인증 메일(비번 재설정 등) 한국어 전송
        if FirebaseApp.app() != nil {
            Auth.auth().languageCode = "ko"
        }

        // 프리뷰/미초기화 상황에서는 Firebase 접근 없음
        guard !BuildEnv.isPreview, FirebaseApp.app() != nil else {
            self.isSignedIn = false
            self.currentUserEmail = nil
            return
        }

        // Auth 상태 리스너
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isSignedIn = (user != nil)
            self.currentUserEmail = user?.email

            if let uid = user?.uid {
                self.fetchProfile(uid: uid)
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
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
            let uid = result.user.uid

            await ensureUserDocumentExists(uid: uid, email: trimmedEmail)
            await updateLastLogin(uid: uid)
        } catch {
            self.authError = koMessage(for: error)
            throw error
        }
        #else
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
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            try await Auth.auth().sendPasswordReset(withEmail: trimmedEmail)
        } catch {
            self.authError = koMessage(for: error)
            throw error
        }
        #else
        authError = nil
        #endif
    }

    // MARK: - 회원가입 (+ Firestore 프로필 최소 생성)
    func signUp(email: String, password: String, nickname: String? = nil) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        authError = nil
        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
            let uid = result.user.uid
            let nick = (nickname?.isEmpty == false) ? nickname! : "코블러"

            try await createUserDocument(uid: uid, email: trimmedEmail, nickname: nick)
        } catch {
            self.authError = koMessage(for: error)
            throw error
        }
        #else
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

    private func createUserDocument(uid: String, email: String, nickname: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db else { return }
        let data: [String: Any] = [
            "nickname": nickname,
            "email": email,
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

    // MARK: - 에러 한국어 변환 (✅ 수정 포인트: AuthErrorCode 사용)
    private func koMessage(for error: Error) -> String {
        let ns = error as NSError
        guard let code = AuthErrorCode(rawValue: ns.code) else {
            return "요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요. (\(ns.code))"
        }
        switch code {
        case .invalidEmail:            // 17008
            return "이메일 주소 형식이 올바르지 않습니다."
        case .wrongPassword:           // 17009
            return "비밀번호가 올바르지 않습니다."
        case .invalidCredential:       // 17004 ← ✅ 추가
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .userNotFound:            // 17011
            return "해당 이메일의 계정을 찾을 수 없습니다."
        case .userDisabled:            // 17005
            return "해당 계정은 비활성화되어 있습니다."
        case .emailAlreadyInUse:       // 17007
            return "이미 사용 중인 이메일 주소입니다."
        case .weakPassword:            // 17026
            return "비밀번호가 너무 약합니다. 더 강한 비밀번호를 사용해 주세요."
        case .tooManyRequests:         // 17010
            return "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요."
        case .networkError:            // 17020
            return "네트워크 오류가 발생했습니다. 연결을 확인하고 다시 시도해 주세요."
        case .requiresRecentLogin:     // 17014
            return "보안을 위해 최근 로그인 후 다시 시도해 주세요."
        case .operationNotAllowed:     // 17006
            return "이 인증 방법은 현재 허용되지 않습니다."
        default:
            // 필요 시 디버깅을 위해 코드도 같이 표기
            return "문제가 발생했습니다. 잠시 후 다시 시도해 주세요. (\(code.rawValue))"
        }
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
    @DocumentID var id: String?
    var nickname: String
    var email: String
    var level: Int?
    var exp: Int?
    var profileImageURL: String?
    @ServerTimestamp var createdAt: Date?
    var character: UserCharacter
    var settings: UserSettings
    @ServerTimestamp var lastLogin: Date?
}

// MARK: - Profile & Account Updates
extension AuthViewModel {
    func updateNickname(_ nickname: String) async throws {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard let db = db else { return }
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인이 필요합니다."])
        }
        authError = nil
        do {
            try await db.collection("users").document(uid).setData(["nickname": nickname], merge: true)
            await MainActor.run {
                if var profile = self.userProfile {
                    profile.nickname = nickname
                    self.userProfile = profile
                } else {
                    self.fetchProfile(uid: uid)
                }
            }
        } catch {
            await MainActor.run { self.authError = self.koMessage(for: error) }
            throw error
        }
        #endif
    }

    func updateEmail(_ newEmail: String) async throws {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard FirebaseApp.app() != nil else { return }
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인이 필요합니다."])
        }
        authError = nil
        do {
            let trimmed = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            try await user.updateEmail(to: trimmed) // 최근 로그인 필요할 수 있음
            if let db = db {
                try await db.collection("users").document(user.uid).setData(["email": trimmed], merge: true)
            }
            await MainActor.run {
                self.currentUserEmail = trimmed
                if var profile = self.userProfile {
                    profile.email = trimmed
                    self.userProfile = profile
                }
            }
        } catch {
            await MainActor.run { self.authError = self.koMessage(for: error) }
            throw error
        }
        #endif
    }

    func updatePassword(_ newPassword: String) async throws {
        #if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인이 필요합니다."])
        }
        authError = nil
        do {
            try await user.updatePassword(to: newPassword) // 최근 로그인 필요할 수 있음
        } catch {
            await MainActor.run { self.authError = self.koMessage(for: error) }
            throw error
        }
        #endif
    }
}
