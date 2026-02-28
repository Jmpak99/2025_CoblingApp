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

    private var profileListener: ListenerRegistration?
    #endif

    // 현재 로그인 UID를 안전하게 꺼내는 공통 프로퍼티
    var currentUserId: String {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser?.uid ?? ""
        #else
        return userProfile?.id ?? ""
        #endif
    }

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
                self.profileListener?.remove()
                self.profileListener = nil
                self.userProfile = nil
            }
        }
        #endif
    }

    deinit {
        #if canImport(FirebaseAuth)
        if let authListener { Auth.auth().removeStateDidChangeListener(authListener) }
        #endif

        #if canImport(FirebaseFirestore)
        profileListener?.remove()
        profileListener = nil
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

            // 로그인 직후 즉시 1회 강제 리프레시(리스너 수신 지연 대비)
            await refreshUserProfileIfNeeded()
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

            // 가입 직후 리스너 수신 전에 1회 리프레시
            await refreshUserProfileIfNeeded()
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

        #if canImport(FirebaseFirestore)
        profileListener?.remove()
        profileListener = nil
        #endif

        self.isSignedIn = false
        self.currentUserEmail = nil
        self.userProfile = nil
    }

    // MARK: - Firestore I/O
    private func fetchProfile(uid: String) {
        #if canImport(FirebaseFirestore)
        guard let db else { return }

        // 중복 등록 방지
        profileListener?.remove()
        profileListener = nil

        profileListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err = err {
                    self.authError = err.localizedDescription
                    return
                }

                guard let snap else { return }

                if snap.exists {
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
                    }
                    #endif
                }
            }
        #endif
    }

    private func createUserDocument(uid: String, email: String, nickname: String) async throws {
        #if canImport(FirebaseFirestore)
        guard let db else { return }

        // 서버(index.js) 스키마와 맞추기: character에 stage/customization + evolution 필드도 기본값
        let data: [String: Any] = [
            "nickname": nickname,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "character": [
                "stage": "egg",
                "customization": [:] as [String: Any],

                // 진화 연출 플래그 기본값
                "evolutionLevel": 0,
                "evolutionPending": false,
                "evolutionToStage": "egg"
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

    // “정산 완료(rewardSettled) 이후” 프로필을 확실히 최신으로 맞추기 위한 1회 강제 새로고침
    // - 이미 addSnapshotListener가 있어도, 이벤트 타이밍 꼬임/지연 대비용으로 있으면 안정적입니다.
    func refreshUserProfileIfNeeded() async {
        #if canImport(FirebaseFirestore) && canImport(FirebaseAuth)
        guard let db = db else { return }
        let uid = currentUserId
        guard !uid.isEmpty else { return }

        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            guard snap.exists else { return }
            let profile = try snap.data(as: UserProfile.self)
            self.userProfile = profile
        } catch {
            // 여기서 authError를 강하게 띄우면 UX가 거칠 수 있어 필요 시만
            // self.authError = error.localizedDescription
        }
        #endif
    }

    // 진화 확정 처리
    // - EvolutionView “완료” 시점에 호출하면:
    //   1) stage를 evolutionToStage로 확정
    //   2) evolutionPending=false로 내려서 다음 진화가 중복으로 뜨지 않게 함
    func completeEvolutionIfNeeded() async {
        #if canImport(FirebaseFirestore)
        guard let db = db else { return }
        let uid = currentUserId
        guard !uid.isEmpty else { return }

        guard let profile = userProfile else { return }
        let char = profile.character

        guard char.evolutionPending == true else { return }

        // 목표 스테이지가 비어있으면, 서버 정책에 따라 level로 계산하는 fallback도 가능
        let toStage = (char.evolutionToStage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? (char.evolutionToStage ?? char.stage)
            : char.stage

        do {
            try await db.collection("users").document(uid).setData(
                [
                    "character": [
                        "stage": toStage,
                        "evolutionPending": false,
                        "evolutionLevel": 0,
                        "evolutionToStage": toStage,
                        "evolutionCompletedAt": FieldValue.serverTimestamp() // 디버깅/분석용
                    ]
                ],
                merge: true
            )

            // 로컬에도 즉시 반영(리스너 수신 전에 화면 업데이트)
            var newProfile = profile
            newProfile.character.stage = toStage
            newProfile.character.evolutionPending = false
            newProfile.character.evolutionLevel = 0
            newProfile.character.evolutionToStage = toStage
            self.userProfile = newProfile

        } catch {
            // self.authError = error.localizedDescription
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
            level: 1,
            exp: 0,
            profileImageURL: nil,
            createdAt: Date(),
            character: .init(
                stage: "egg",
                customization: [:],
                evolutionLevel: 0,
                evolutionPending: false,
                evolutionToStage: "egg"
            ),
            settings: .init(notificationsEnabled: true, darkMode: false),
            lastLogin: Date()
        )
    }

    // MARK: - 에러 한국어 변환
    private func koMessage(for error: Error) -> String {
        let ns = error as NSError
        guard let code = AuthErrorCode(rawValue: ns.code) else {
            return "요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요. (\(ns.code))"
        }
        switch code {
        case .invalidEmail:
            return "이메일 주소 형식이 올바르지 않습니다."
        case .wrongPassword:
            return "비밀번호가 올바르지 않습니다."
        case .invalidCredential:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .userNotFound:
            return "해당 이메일의 계정을 찾을 수 없습니다."
        case .userDisabled:
            return "해당 계정은 비활성화되어 있습니다."
        case .emailAlreadyInUse:
            return "이미 사용 중인 이메일 주소입니다."
        case .weakPassword:
            return "비밀번호가 너무 약합니다. 더 강한 비밀번호를 사용해 주세요."
        case .tooManyRequests:
            return "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요."
        case .networkError:
            return "네트워크 오류가 발생했습니다. 연결을 확인하고 다시 시도해 주세요."
        case .requiresRecentLogin:
            return "보안을 위해 최근 로그인 후 다시 시도해 주세요."
        case .operationNotAllowed:
            return "이 인증 방법은 현재 허용되지 않습니다."
        default:
            return "문제가 발생했습니다. 잠시 후 다시 시도해 주세요. (\(code.rawValue))"
        }
    }
}

// MARK: - UserProfile 모델 (DB 스키마에 맞춤)

// 서버(index.js)와 동일: stage(egg/kid/cobling/legend) + 진화 필드 포함
struct UserCharacter: Codable {
    var stage: String                         // "egg" | "kid" | "cobling" | "legend"
    var customization: [String: String]?

    // 서버에서 쓰는 진화 플래그
    var evolutionLevel: Int?
    var evolutionPending: Bool?
    var evolutionToStage: String?
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
    func deleteAccount() async throws {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        guard FirebaseApp.app() != nil else { return }
        guard let db = db else { return }
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "로그인이 필요합니다."])
        }
        let uid = user.uid
        authError = nil

        profileListener?.remove()
        profileListener = nil

        do {
            let chapters = try await db.collection("users").document(uid).collection("progress").getDocuments()
            for chapter in chapters.documents {
                let subQuests = try await chapter.reference.collection("subQuests").getDocuments()
                for sq in subQuests.documents {
                    try await sq.reference.delete()
                }
                try await chapter.reference.delete()
            }

            try await db.collection("users").document(uid).delete()

            let mySolutions = try await db.collection("blockSolutions")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()
            for doc in mySolutions.documents {
                try await doc.reference.delete()
            }

            try await db.collection("users").document(uid).delete()
        } catch {
            await MainActor.run { self.authError = self.koMessage(for: error) }
            throw error
        }

        do {
            try await user.delete()
        } catch {
            if let code = AuthErrorCode(rawValue: (error as NSError).code), code == .requiresRecentLogin {
                let msg = "보안을 위해 최근 로그인 후 다시 시도해 주세요."
                await MainActor.run { self.authError = msg }
                throw NSError(domain: "Auth", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: msg])
            } else {
                await MainActor.run { self.authError = self.koMessage(for: error) }
                throw error
            }
        }

        await MainActor.run {
            self.isSignedIn = false
            self.currentUserEmail = nil
            self.userProfile = nil
        }
        #endif
    }

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
            try await user.updateEmail(to: trimmed)
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
            try await user.updatePassword(to: newPassword)
        } catch {
            await MainActor.run { self.authError = self.koMessage(for: error) }
            throw error
        }
        #endif
    }
}
