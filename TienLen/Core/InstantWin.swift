import Foundation

enum InstantWinKind: String {
    case dragonStraight   // sảnh rồng — all 13 non-2 ranks (3..A) represented in the dealt hand
    case fourTwos         // tứ quý heo — all four 2s in the dealt hand

    var titleKey: String {
        switch self {
        case .dragonStraight: return "win.dragonStraight"
        case .fourTwos: return "win.fourTwos"
        }
    }

    /// Payout multiplier applied to the base stake for an instant "tới trắng" win.
    var payoutMultiplier: Int {
        switch self {
        case .dragonStraight: return 20
        case .fourTwos: return 16
        }
    }
}

enum InstantWinDetector {
    /// Checks a freshly-dealt 13-card hand for a "tới trắng" instant win, in priority order:
    /// Sảnh Rồng (Dragon Straight) > Tứ Quý Heo (Four 2s).
    static func detect(hand: [Card]) -> InstantWinKind? {
        guard hand.count == 13 else { return nil }
        if isDragonStraight(hand) { return .dragonStraight }
        if hand.filter({ $0.rank == .two }).count == 4 { return .fourTwos }
        return nil
    }

    /// Sảnh Rồng: every rank from 3 to Ace (the 12 non-2 ranks) is represented at least
    /// once among the 13 cards, with no 2s at all. Since there are only 12 non-2 ranks and
    /// 13 cards in hand, exactly one rank is necessarily held twice — that's expected and
    /// still counts (this is the standard definition, not a strict "each rank exactly once"
    /// straight).
    private static func isDragonStraight(_ hand: [Card]) -> Bool {
        guard hand.allSatisfy({ $0.rank.isStraightEligible }) else { return false }
        return Set(hand.map { $0.rank }).count == 12
    }
}
