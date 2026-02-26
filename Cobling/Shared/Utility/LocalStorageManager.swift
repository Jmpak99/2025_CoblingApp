//
//  LocalStorageManager.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation

/// UserDefaults 기반 로컬 저장 유틸
/// - 온보딩 여부, 튜토리얼/컷씬(인트로/아웃트로) 1회 노출 여부 등 저장용
enum LocalStorageManager {

    // MARK: - Keys
    private static func key(_ raw: String) -> String {
        // 앱 키 네임스페이스(충돌 방지)
        "cobling.\(raw)"
    }

    // MARK: - Generic Helpers
    static func setBool(_ value: Bool, for rawKey: String) {
        UserDefaults.standard.set(value, forKey: key(rawKey))
    }

    static func getBool(for rawKey: String, default defaultValue: Bool = false) -> Bool {
        if UserDefaults.standard.object(forKey: key(rawKey)) == nil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key(rawKey))
    }

    static func remove(_ rawKey: String) {
        UserDefaults.standard.removeObject(forKey: key(rawKey))
    }

    // MARK: - Chapter Cutscene (Intro/Outro)
    private static func cutsceneKey(chapterId: String, type: ChapterCutsceneType) -> String {
        // 예: cobling.cutscene_shown_intro_ch1
        "cutscene_shown_\(type.rawValue)_\(chapterId.lowercased())"
    }

    /// 인트로/아웃트로 컷씬을 이미 봤는지
    static func isCutsceneShown(chapterId: String, type: ChapterCutsceneType) -> Bool {
        getBool(for: cutsceneKey(chapterId: chapterId, type: type), default: false)
    }

    /// 인트로/아웃트로 컷씬을 봤다고 기록
    static func setCutsceneShown(chapterId: String, type: ChapterCutsceneType) {
        setBool(true, for: cutsceneKey(chapterId: chapterId, type: type))
    }

    /// 디버그/테스트용: 특정 챕터 컷씬 기록 삭제
    static func clearCutsceneShown(chapterId: String, type: ChapterCutsceneType) {
        remove(cutsceneKey(chapterId: chapterId, type: type))
    }

    /// 디버그/테스트용: 모든 컷씬 기록 초기화 (필요하면 사용)
    static func clearAllCutsceneShownForChapters(_ chapterIds: [String]) {
        for ch in chapterIds {
            clearCutsceneShown(chapterId: ch, type: .intro)
            clearCutsceneShown(chapterId: ch, type: .outro)
        }
    }
}
