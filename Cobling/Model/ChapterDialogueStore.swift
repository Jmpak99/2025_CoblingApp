//
//  ChapterDialogueStore.swift
//  Cobling
//
//  Created by 박종민 on 2/26/26.
//

import Foundation

enum ChapterDialogueStore {

    // 챕터별 대사 딕셔너리
    // key: "ch1", "ch2" ...
    private static let intro: [String: [DialogueLine]] = [
        "ch1": [
            DialogueLine(speaker: .cobling, text: "여긴…\n어디지?"),
            DialogueLine(speaker: .spirit,  text: "코드가 잠들어 있는 숲이야."),
            DialogueLine(speaker: .cobling, text: "코드..??"),
            DialogueLine(speaker: .spirit,  text: "흐름이 멈추고, 길이 잊혀진 곳"),
            DialogueLine(speaker: .cobling, text: "그럼… 난 왜 여기 있어?"),
            DialogueLine(speaker: .spirit,  text: "네가 움직이면,\n흐름은 다시 이어질 거야."),
            DialogueLine(speaker: .cobling, text: "…내가?"),
            DialogueLine(speaker: .spirit,  text: "응. \n 첫 걸음부터 시작해보자")
        ],
        
        "ch2" : [
            DialogueLine(speaker: .cobling, text: "길이 막혀 있어…"),
            DialogueLine(speaker: .spirit,  text: "막힌 게 아니라, 붙잡혀 있는 거야"),
            DialogueLine(speaker: .cobling, text: "붙잡혀 있다고?"),
            DialogueLine(speaker: .spirit,  text: "왜곡된 코드가 숲을 잠식하고 있어"),
            DialogueLine(speaker: .cobling, text: "…그럼, 없애야 하는 거야?")
        ]
    ]

    private static let outro: [String: [DialogueLine]] = [
        "ch1": [
            DialogueLine(speaker: .cobling, text: "나… 움직였어."),
            DialogueLine(speaker: .spirit, text: "그래."),
            DialogueLine(speaker: .cobling, text: "아무것도 몰랐는데… 길이 보였어."),
            DialogueLine(speaker: .spirit, text: "움직이면, 보이기 시작해."),
            DialogueLine(speaker: .cobling, text: "그럼… 더 가볼래."),
            DialogueLine(speaker: .spirit, text: "그래.\n이제 시작이야.")
        ],
        "ch2": [
            DialogueLine(speaker: .cobling, text: "사라졌어…"),
            DialogueLine(speaker: .cobling, text: "왜곡된 코드가 정리됐어"),
            DialogueLine(speaker: .spirit,  text: "그래"),
            DialogueLine(speaker: .spirit,  text: "밀어낼 힘은 생겼어"),
            DialogueLine(speaker: .cobling, text: "이제 막혀도 괜찮겠지?"),
            DialogueLine(speaker: .spirit,  text: "항상 그런 건 아니야"),
            DialogueLine(speaker: .cobling, text: "…또 다른 문제가 있다는 거야?"),
            DialogueLine(speaker: .spirit,  text: "왜곡은 한 번으로 끝나지 않아"),
            DialogueLine(speaker: .spirit,  text: "같은 흐름이… 계속 반복되기도 해"),
            DialogueLine(speaker: .cobling, text: "같은 흐름이… 반복된다고?"),
            DialogueLine(speaker: .spirit,  text: "응. \n다음 숲에서는, 그걸 보게 될 거야")
        ]
        // "ch2": [...],
    ]

    // 외부에서 호출하는 API
    static func lines(chapterId: String, type: ChapterCutsceneType) -> [DialogueLine] {
        let key = chapterId.lowercased()
        switch type {
        case .intro:
            return intro[key] ?? defaultIntro
        case .outro:
            return outro[key] ?? defaultOutro
        }
    }

    // 기본 대사 (챕터 없을 때)
    private static let defaultIntro: [DialogueLine] = [
        DialogueLine(speaker: .spirit, text: "새로운 챕터가 열렸어요.\n준비되면 시작해볼까요?"),
        DialogueLine(speaker: .cobling, text: "응!\n해볼래!")
    ]

    private static let defaultOutro: [DialogueLine] = [
        DialogueLine(speaker: .spirit, text: "좋았어요.\n다음으로 가볼까요?"),
        DialogueLine(speaker: .cobling, text: "응! 계속하자!")
    ]
}
