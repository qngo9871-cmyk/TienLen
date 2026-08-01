import Foundation

enum ComboShape: Equatable {
    case single
    case pair
    case triple
    case straight(length: Int)          // sảnh — 3+ consecutive ranks, ANY suits, no 2s
    case fourOfAKind                    // tứ quý — a bomb
    case pairStraight(length: Int)      // đôi thông — 3+ consecutive pairs (length = pair count), a bomb

    var sortKey: Int {
        switch self {
        case .single: return 0
        case .pair: return 1
        case .triple: return 2
        case .straight(let n): return 100 + n
        case .fourOfAKind: return 900
        case .pairStraight(let n): return 900 + n
        }
    }

    /// nil if not a bomb. Otherwise the tier used to compare across bomb *types* per the
    /// Tiến Lên bomb hierarchy (weakest -> strongest):
    ///   3-pair straight < four-of-a-kind < 4-pair straight < 5-pair straight < ...
    /// Each additional pair in a pair-straight is one tier stronger, and any pair-straight
    /// of length N+1 beats a four-of-a-kind and any pair-straight of length <= N.
    var bombTier: Int? {
        switch self {
        case .pairStraight(let n) where n == 3: return 0
        case .fourOfAKind: return 1
        case .pairStraight(let n): return n - 2 // n >= 4 -> 2, 3, 4, ...
        default: return nil
        }
    }
}

struct Combo {
    let cards: [Card]
    let shape: ComboShape
    /// Highest-rank card in the combo, used to compare same-shape (or same-bomb-tier) combos.
    let topRank: Rank

    var isBomb: Bool { shape.bombTier != nil }

    /// True if `self` legally beats `other` when played on top of it.
    /// A bomb beats every non-bomb combo regardless of shape (this is how a tứ quý or
    /// đôi thông "chặt heo" — cuts a lone 2 — since a single 2 is a non-bomb combo like any
    /// other). Between two bombs, only a strictly higher bomb tier (or same tier + higher
    /// rank) wins.
    func beats(_ other: Combo) -> Bool {
        if let selfTier = shape.bombTier {
            guard let otherTier = other.shape.bombTier else { return true }
            if selfTier != otherTier { return selfTier > otherTier }
            return topRank > other.topRank
        }
        if other.shape.bombTier != nil { return false }
        guard sameShapeFamily(other) else { return false }
        return topRank > other.topRank
    }

    private func sameShapeFamily(_ other: Combo) -> Bool {
        switch (shape, other.shape) {
        case (.single, .single), (.pair, .pair), (.triple, .triple): return true
        case (.straight(let a), .straight(let b)): return a == b
        default: return false
        }
    }

    /// Attempts to build the strongest valid combo shape from an exact set of selected cards.
    /// Returns nil if the selection isn't a legal shape.
    static func make(from cards: [Card]) -> Combo? {
        guard !cards.isEmpty else { return nil }
        let sorted = cards.sorted { $0.rank < $1.rank }
        let byRank = Dictionary(grouping: sorted, by: { $0.rank })
        let ranks = Set(sorted.map { $0.rank })

        if cards.count == 1 {
            return Combo(cards: sorted, shape: .single, topRank: sorted[0].rank)
        }
        if ranks.count == 1 {
            switch cards.count {
            case 2: return Combo(cards: sorted, shape: .pair, topRank: sorted[0].rank)
            case 3: return Combo(cards: sorted, shape: .triple, topRank: sorted[0].rank)
            case 4: return Combo(cards: sorted, shape: .fourOfAKind, topRank: sorted[0].rank)
            default: return nil
            }
        }

        // Straight (sảnh): ANY suits, consecutive ranks, one card per rank, length >= 3, no 2s.
        // (Unlike Sâm Lốc, suit does NOT gate straight legality here.)
        if cards.count >= 3, ranks.count == cards.count,
           sorted.allSatisfy({ $0.rank.isStraightEligible }) {
            let rankValues = sorted.map { $0.rank.rawValue }
            let isConsecutive = zip(rankValues, rankValues.dropFirst()).allSatisfy { $1 == $0 + 1 }
            if isConsecutive {
                return Combo(cards: sorted, shape: .straight(length: cards.count), topRank: sorted.last!.rank)
            }
        }

        // Pair-straight / đôi thông: 3+ consecutive ranks, exactly 2 cards of each, no 2s.
        if cards.count >= 6, cards.count % 2 == 0 {
            let pairCount = cards.count / 2
            if ranks.count == pairCount, byRank.values.allSatisfy({ $0.count == 2 }),
               ranks.allSatisfy({ $0.isStraightEligible }) {
                let sortedRanks = ranks.sorted()
                let rankValues = sortedRanks.map { $0.rawValue }
                let isConsecutive = zip(rankValues, rankValues.dropFirst()).allSatisfy { $1 == $0 + 1 }
                if isConsecutive {
                    return Combo(cards: sorted, shape: .pairStraight(length: pairCount), topRank: sortedRanks.last!)
                }
            }
        }

        return nil
    }
}
