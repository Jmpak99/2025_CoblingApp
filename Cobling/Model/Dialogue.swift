//
//  Dialogue.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//

import Foundation

enum DialogueSpeaker: String, Codable {
    case cobling
    case spirit

    var displayName: String {
        switch self {
        case .cobling: return "코블링"
        case .spirit: return "숲의 정령"
        }
    }

    /// 화면에서 어느 쪽 캐릭터인지
    var isLeftSide: Bool {
        switch self {
        case .cobling: return true
        case .spirit: return false
        }
    }
}

struct DialogueLine: Identifiable, Codable, Equatable {
    let id: String
    let speaker: DialogueSpeaker
    let text: String

    init(id: String = UUID().uuidString, speaker: DialogueSpeaker, text: String) {
        self.id = id
        self.speaker = speaker
        self.text = text
    }
}
