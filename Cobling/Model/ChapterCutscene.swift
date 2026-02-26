//
//  ChapterCutscene.swift
//  Cobling
//
//  Created by 박종민 on 2/26/26.
//

import Foundation

enum ChapterCutsceneType: String, Codable {
    case intro
    case outro

    var primaryButtonTitle: String {
        switch self {
        case .intro: return "시작하기"
        case .outro: return "계속하기"
        }
    }
}

struct ChapterCutscene: Identifiable, Codable, Equatable {
    var id: String { "\(chapterId)_\(type.rawValue)" }

    let chapterId: String
    let type: ChapterCutsceneType
    let lines: [DialogueLine]

    /// 배경/캐릭터 에셋 (없으면 기본 Color로 처리)
    let backgroundAssetName: String?
    let coblingAssetName: String?
    let spiritAssetName: String?

    init(
        chapterId: String,
        type: ChapterCutsceneType,
        lines: [DialogueLine],
        backgroundAssetName: String? = nil,
        coblingAssetName: String? = nil,
        spiritAssetName: String? = nil
    ) {
        self.chapterId = chapterId
        self.type = type
        self.lines = lines
        self.backgroundAssetName = backgroundAssetName
        self.coblingAssetName = coblingAssetName
        self.spiritAssetName = spiritAssetName
    }
}
