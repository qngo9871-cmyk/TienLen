import Foundation

#if DEBUG
extension GameModel {
    /// Deterministic states for App Store screenshot capture, keyed by TL_CAPTURE value.
    func captureSetup(_ scenario: String) {
        difficulty = .normal
        matchScores = [42, -18, -12, -12]
        roundsWon = [1, 0, 0, 0]
        roundNumber = 2

        let deck = [Card].freshDeck()
        func hand(_ ranks: [Rank], _ suits: [Suit]) -> [Card] {
            zip(ranks, suits).map { Card(rank: $0, suit: $1) }
        }

        switch scenario {
        case "instantwin":
            // Sảnh Rồng: every rank 3...A represented (12 ranks), one duplicated to reach 13.
            let dragonRanks: [Rank] = [.three, .four, .five, .six, .seven, .eight, .nine, .ten,
                                        .jack, .queen, .king, .ace, .three]
            let dragonSuits: [Suit] = [.hearts, .hearts, .hearts, .hearts, .hearts, .hearts,
                                        .hearts, .hearts, .hearts, .hearts, .hearts, .hearts, .spades]
            players = [
                Player(id: 0, name: L(names[0]), hand: hand(dragonRanks, dragonSuits), isHuman: true),
                Player(id: 1, name: L(names[1]), hand: Array(deck.shuffled().prefix(8)), isHuman: false),
                Player(id: 2, name: L(names[2]), hand: Array(deck.shuffled().prefix(10)), isHuman: false),
                Player(id: 3, name: L(names[3]), hand: Array(deck.shuffled().prefix(11)), isHuman: false),
            ]
            instantWin = (0, .dragonStraight)
            roundOver = true
            roundLog = [String(format: L("log.instantWin"), players[0].name, L(InstantWinKind.dragonStraight.titleKey))]

        default: // "midgame"
            players = [
                Player(id: 0, name: L(names[0]),
                       hand: hand([.six, .seven, .nine, .jack, .jack, .queen, .queen, .king, .ace, .two],
                                  [.spades, .clubs, .hearts, .diamonds, .spades, .clubs, .hearts, .diamonds, .hearts, .spades]),
                       isHuman: true),
                Player(id: 1, name: L(names[1]), hand: Array(deck.shuffled().prefix(9)), isHuman: false),
                Player(id: 2, name: L(names[2]), hand: Array(deck.shuffled().prefix(11)), isHuman: false),
                Player(id: 3, name: L(names[3]), hand: Array(deck.shuffled().prefix(7)), isHuman: false),
            ]
            tableCombo = Combo(cards: [Card(rank: .nine, suit: .diamonds)], shape: .single, topRank: .nine)
            lastPlayerToPlay = 1
            currentTurnIndex = 0
            roundLog = [String(format: L("log.played"), players[1].name, "9♦")]
        }
    }
}
#endif
