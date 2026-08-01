import Foundation

struct Player: Identifiable {
    let id: Int
    var name: String
    var hand: [Card] = []
    let isHuman: Bool
    var finishedRank: Int? = nil     // 1st, 2nd, 3rd, 4th to empty their hand
    var hasPlayed: Bool = false      // tracks whether this player ever laid down a card this
                                      // round — used for the "cóng" (skunked) scoring penalty.

    var isFinished: Bool { finishedRank != nil }
}

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy, normal, hard
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .easy: return "difficulty.easy"
        case .normal: return "difficulty.normal"
        case .hard: return "difficulty.hard"
        }
    }
}
