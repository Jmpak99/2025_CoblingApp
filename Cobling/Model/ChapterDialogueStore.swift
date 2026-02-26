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
        ],
        
        "ch3" : [
            DialogueLine(speaker: .cobling, text: "이 길… 아까랑 똑같은 것 같은데?"),
            DialogueLine(speaker: .spirit,  text: "눈에 보이는 것만 따라가면 멀어져"),
            DialogueLine(speaker: .spirit,  text: "흐름을 읽어야 해"),
            DialogueLine(speaker: .cobling, text: "흐름을… 읽는다고?"),
        ],
        
        "ch4" : [
            DialogueLine(speaker: .cobling, text: "이상해…"),
            DialogueLine(speaker: .cobling, text: "아까랑 같은 길 같은데, 막혀 있어"),
            DialogueLine(speaker: .spirit,  text: "흐름은 반복되지만, 항상 그대로는 아니야"),
            DialogueLine(speaker: .cobling, text: "그럼… 이번엔 어떻게 해야 해?"),
            DialogueLine(speaker: .spirit,  text: "움직이기 전에, 잠깐 바라보면 보여"),
            DialogueLine(speaker: .cobling, text: "…먼저 보고 움직이라는 거지?"),
            DialogueLine(speaker: .spirit,  text: "응"),
            DialogueLine(speaker: .spirit,  text: "흐름은, 선택을 기다리고 있어"),
        ],
        
        "ch5" : [
            DialogueLine(speaker: .cobling, text: "적은… 이미 만나봤어"),
            DialogueLine(speaker: .spirit,  text: "그래"),
            DialogueLine(speaker: .spirit,  text: "하지만 이번엔 조금 달라"),
            DialogueLine(speaker: .cobling, text: "뭐가 다른데?"),
            DialogueLine(speaker: .spirit,  text: "멈춰서 기다려주지 않아"),
            DialogueLine(speaker: .spirit,  text: "흐름은 계속 이어지고 있어"),
            DialogueLine(speaker: .cobling, text: "…그럼 움직이면서 해야 하는 거구나"),
            DialogueLine(speaker: .spirit,  text: "응"),
            DialogueLine(speaker: .spirit,  text: "같은 움직임 속에서도, 공격할 순간은 다시 찾아와"),
            DialogueLine(speaker: .cobling, text: "흐름 안에서… 공격하는 거네"),
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
        ],
        
        "ch3" : [
            DialogueLine(speaker: .spirit,  text: "같은 흐름은 반복된다"),
            DialogueLine(speaker: .cobling, text: "…그래서 길이 짧아졌구나"),
            DialogueLine(speaker: .spirit,  text: "그래"),
            DialogueLine(speaker: .spirit,  text: "흐름을 이해하면, 움직임은 줄어들지"),
            DialogueLine(speaker: .cobling, text: "이제는 헤매지 않을 것 같아"),
            DialogueLine(speaker: .spirit,  text: "하지만 숲은 항상 같은 모습은 아니야"),
            DialogueLine(speaker: .cobling, text: "…같지 않다고?"),
            DialogueLine(speaker: .spirit,  text: "어떤 길은, 멈춰야 할 때를 묻기도 해"),
            DialogueLine(speaker: .cobling, text: "멈춰야 할 때를…?"),
        ],
        
        "ch4" : [
            DialogueLine(speaker: .cobling, text: "이제는 멈추고 생각할 수 있어"),
            DialogueLine(speaker: .spirit,  text: "그래"),
            DialogueLine(speaker: .spirit,  text: "상황을 보는 눈이 생겼어"),
            DialogueLine(speaker: .cobling, text: "그럼… 이제 길은 두렵지 않아"),
            DialogueLine(speaker: .spirit,  text: "하지만 다음 숲은 조금 달라"),
            DialogueLine(speaker: .cobling, text: "…달라?"),
            DialogueLine(speaker: .spirit,  text: "멈춰 있을 수만은 없을 거야"),
            DialogueLine(speaker: .spirit,  text: "움직이는 동안, 맞서야 할 것들이 있어"),
            DialogueLine(speaker: .cobling, text: "응"),
            DialogueLine(speaker: .spirit,  text: "흐름을 유지하면서"),
        ],
        
        "ch5" : [
            DialogueLine(speaker: .cobling, text: "이제는 멈추지 않아도 괜찮아"),
            DialogueLine(speaker: .cobling, text: "움직이면서도… 싸울 수 있어"),
            DialogueLine(speaker: .spirit,  text: "그래"),
            DialogueLine(speaker: .spirit,  text: "흐름을 지키면서도, 선택할 수 있게 됐어"),
            DialogueLine(speaker: .cobling, text: "전투도… 하나의 리듬이구나"),
            DialogueLine(speaker: .spirit,  text: "응"),
            DialogueLine(speaker: .spirit,  text: "그리고 어떤 리듬은, 스스로 멈출 때까지 이어지기도 해"),
            DialogueLine(speaker: .cobling, text: "…멈출 때까지?"),
            DialogueLine(speaker: .spirit,  text: "조건이 닿을 때까지, 흐름은 계속될 수 있어"),
            DialogueLine(speaker: .cobling, text: "끝이 정해진 게 아니라… 이어지는 거구나"),
            DialogueLine(speaker: .spirit,  text: "더 깊은 구조가 기다리고 있어"),
        ]
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
