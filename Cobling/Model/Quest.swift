//
//  Quest.swift
//  Cobling
//
//  Created by 박종민 on 6/20/25.
//


import FirebaseFirestore

struct SubQuestDocument: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var objective: String
    var order: Int
    var isActive: Bool
    var preId: String?
    var rewards: Rewards
    var rules: Rules
    var map: MapData
}

// MARK: - MapData
struct MapData: Codable {
    var goal: Position
    var start: Position
    var grid: [String]     // "0,1,0,0" 이런 문자열 배열
    var size: MapSize
    var startDirection: String
    var legend: Legend
    
    /// grid([String]) → [[Int]] 변환
    var parsedGrid: [[Int]] {
        grid.map { rowString in
            rowString
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
    }
}

// MARK: - Supporting Models
struct Position: Codable {
    var row: Int
    var col: Int
}

struct MapSize: Codable {
    var rows: Int
    var cols: Int
}

struct Legend: Codable {
    var empty: Int
    var path: Int
    var start: Int
    var goal: Int
}

struct Rewards: Codable {
    var baseExp: Int
    var perfectBonusExp: Int
}

struct Rules: Codable {
    var allowBlocks: [String]
    var attackRange: Int
    var maxSteps: Int
}
