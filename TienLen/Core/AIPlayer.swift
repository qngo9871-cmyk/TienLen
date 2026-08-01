import Foundation

enum AIPlayer {
    /// Returns the combo the AI wants to play, or nil to pass. (Unlike Sâm Lốc, Tiến Lên has
    /// no "can't finish on a lone 2" restriction, so there's no filtering of finishing moves here.)
    static func chooseMove(hand: [Card], mustBeat: Combo?, difficulty: AIDifficulty) -> Combo? {
        let options = legalPlays(hand: hand, mustBeat: mustBeat)
        guard !options.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            // Plays the weakest legal option — easy to beat, rarely holds back bombs.
            return options.min { $0.topRank < $1.topRank || ($0.topRank == $1.topRank && $0.shape.sortKey < $1.shape.sortKey) }

        case .normal:
            // Prefers clearing small singles/pairs early, saves triples/straights/bombs for later.
            if mustBeat == nil {
                let nonBomb = options.filter { !$0.isBomb }
                return (nonBomb.isEmpty ? options : nonBomb).min { $0.topRank < $1.topRank }
            }
            return options.min { $0.topRank < $1.topRank }

        case .hard:
            return chooseHardMove(hand: hand, mustBeat: mustBeat, options: options)
        }
    }

    /// Hard AI reasons about hand shape: hangs onto bombs and the "heo" (2) as long as
    /// possible, prefers to burn off cards that don't combo with the rest of its hand,
    /// and leads with its longest straight when it has the table free (card-shape reading,
    /// not just picking the weakest legal move).
    private static func chooseHardMove(hand: [Card], mustBeat: Combo?, options: [Combo]) -> Combo? {
        if mustBeat == nil {
            // Leading: dump the biggest "dead" combo (cards that don't extend into anything else)
            // first, holding pairs/triples/straights and the 2 in reserve.
            let byUsefulness = options.sorted { comboUsefulness(hand: hand, $0) < comboUsefulness(hand: hand, $1) }
            return byUsefulness.first
        }

        // Following: play the smallest combo that still wins the trick, unless only a bomb
        // or the 2 can beat it — then weigh whether it's worth burning a premium card.
        let nonPremium = options.filter { !$0.isBomb && $0.topRank != .two }
        if let cheapest = nonPremium.min(by: { $0.topRank < $1.topRank }) {
            return cheapest
        }
        // Only bombs/2s can win — hold back roughly a third of the time to keep the "heo" in reserve.
        if hand.count > 3, Bool.random(probability: 0.35) { return nil }
        return options.min { $0.topRank < $1.topRank }
    }

    /// Lower score = less useful to keep (safer to discard early). Cards that are part of a
    /// pair/triple/straight elsewhere in the hand score higher (worth holding onto).
    private static func comboUsefulness(hand: [Card], _ combo: Combo) -> Int {
        var score = combo.topRank.rawValue
        if combo.topRank == .two { score += 50 }
        if combo.isBomb { score += 100 }
        let rankCounts = Dictionary(grouping: hand, by: { $0.rank }).mapValues { $0.count }
        if combo.shape == .single, let count = rankCounts[combo.topRank], count > 1 {
            score += 10 // this card is part of a pair/triple elsewhere — prefer not to break it up
        }
        return score
    }

    static func legalPlays(hand: [Card], mustBeat: Combo?) -> [Combo] {
        var combos: [Combo] = []
        let byRank = Dictionary(grouping: hand, by: { $0.rank })

        // Singles
        combos.append(contentsOf: hand.map { Combo(cards: [$0], shape: .single, topRank: $0.rank) })

        // Pairs / triples / four-of-a-kind
        for (rank, cards) in byRank {
            let sortedCards = cards.sorted { $0.suit < $1.suit }
            if sortedCards.count >= 2 { combos.append(Combo(cards: Array(sortedCards.prefix(2)), shape: .pair, topRank: rank)) }
            if sortedCards.count >= 3 { combos.append(Combo(cards: Array(sortedCards.prefix(3)), shape: .triple, topRank: rank)) }
            if sortedCards.count == 4 { combos.append(Combo(cards: sortedCards, shape: .fourOfAKind, topRank: rank)) }
        }

        // Straights (sảnh): ANY suits, consecutive ranks, length 3+, no 2s. One representative
        // card per rank in the run (the specific suit doesn't matter for legality here).
        let eligibleRanks = Rank.allCases.filter { $0.isStraightEligible && byRank[$0] != nil }.sorted { $0.rawValue < $1.rawValue }
        for run in consecutiveRuns(eligibleRanks) where run.count >= 3 {
            for start in 0..<run.count {
                let maxLen = run.count - start
                guard maxLen >= 3 else { continue }
                for length in 3...maxLen {
                    let window = Array(run[start..<(start + length)])
                    let cards = window.compactMap { byRank[$0]?.sorted(by: { $0.suit < $1.suit }).first }
                    guard cards.count == window.count else { continue }
                    combos.append(Combo(cards: cards, shape: .straight(length: cards.count), topRank: window.last!))
                }
            }
        }

        // Pair-straights (đôi thông): 3+ consecutive ranks with >= 2 cards each, no 2s.
        let pairEligibleRanks = eligibleRanks.filter { (byRank[$0]?.count ?? 0) >= 2 }
        for run in consecutiveRuns(pairEligibleRanks) where run.count >= 3 {
            for start in 0..<run.count {
                let maxLen = run.count - start
                guard maxLen >= 3 else { continue }
                for length in 3...maxLen {
                    let window = Array(run[start..<(start + length)])
                    let cards = window.flatMap { byRank[$0]!.sorted(by: { $0.suit < $1.suit }).prefix(2) }
                    combos.append(Combo(cards: cards, shape: .pairStraight(length: window.count), topRank: window.last!))
                }
            }
        }

        guard let mustBeat else { return combos }
        return combos.filter { $0.beats(mustBeat) }
    }

    /// Groups a sorted list of ranks into maximal runs of consecutive rank values.
    private static func consecutiveRuns(_ ranks: [Rank]) -> [[Rank]] {
        var runs: [[Rank]] = []
        var current: [Rank] = []
        for rank in ranks {
            if let last = current.last, rank.rawValue == last.rawValue + 1 {
                current.append(rank)
            } else {
                if !current.isEmpty { runs.append(current) }
                current = [rank]
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }
}

private extension Bool {
    static func random(probability: Double) -> Bool { Double.random(in: 0...1) < probability }
}
