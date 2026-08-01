import Foundation
import Combine

@MainActor
final class GameModel: ObservableObject {
    static let stakeUnit = 1

    @Published var players: [Player] = []
    @Published var currentTurnIndex: Int = 0
    @Published var tableCombo: Combo? = nil
    @Published var lastPlayerToPlay: Int? = nil
    @Published var roundOver = false
    @Published var matchOver = false
    @Published var roundLog: [String] = []
    @Published var instantWin: (playerIndex: Int, kind: InstantWinKind)? = nil
    @Published var roundNumber = 1
    @Published var matchScores: [Int] = [0, 0, 0, 0]
    @Published var roundsWon: [Int] = [0, 0, 0, 0]
    @Published var congIndices: [Int] = [] // players "cóng" (skunked) at the most recent round end

    var difficulty: AIDifficulty = .easy
    private var passStreak = 0
    private let matchTarget = 3 // best-of-... rounds won to end the match

    let names = ["home.player.you", "home.player.left", "home.player.across", "home.player.right"]

    func startMatch(difficulty: AIDifficulty) {
        self.difficulty = difficulty
        matchScores = [0, 0, 0, 0]
        roundsWon = [0, 0, 0, 0]
        roundNumber = 1
        matchOver = false
        startRound()
    }

    func startRound() {
        roundOver = false
        instantWin = nil
        congIndices = []
        tableCombo = nil
        lastPlayerToPlay = nil
        passStreak = 0
        roundLog = []

        // Standard 52-card deck, 4 players, 13 cards each — uses the entire deck exactly.
        var deck = [Card].freshDeck().shuffled()
        players = (0..<4).map { i in
            let hand = Array(deck.prefix(13))
            deck.removeFirst(13)
            return Player(id: i, name: L(names[i]), hand: hand.sorted(by: cardSortOrder), isHuman: i == 0)
        }

        // Check every hand for a "tới trắng" instant win before play begins.
        for i in 0..<4 {
            if let kind = InstantWinDetector.detect(hand: players[i].hand) {
                instantWin = (i, kind)
                settleInstantWin(winner: i, kind: kind)
                return
            }
        }

        currentTurnIndex = startingLeader()
        log(String(format: L("log.leads"), players[currentTurnIndex].name))
        maybeTriggerAI()
    }

    private func startingLeader() -> Int {
        // Whoever holds the 3 of spades leads the very first trick.
        for i in 0..<4 {
            if players[i].hand.contains(where: { $0.rank == .three && $0.suit == .spades }) {
                return i
            }
        }
        return 0
    }

    private func cardSortOrder(_ a: Card, _ b: Card) -> Bool {
        a.rank == b.rank ? a.suit < b.suit : a.rank < b.rank
    }

    // MARK: - Playing

    var currentPlayer: Player { players[currentTurnIndex] }

    @discardableResult
    func play(playerIndex: Int, cards: [Card]) -> Bool {
        guard playerIndex == currentTurnIndex, !players[playerIndex].isFinished else { return false }
        guard let combo = Combo.make(from: cards) else { return false }
        if let table = tableCombo, !combo.beats(table) { return false }

        // Note: unlike Sâm Lốc, Tiến Lên has no "can't finish on a lone 2" restriction — a
        // player may legally go out by playing a 2 as their very last card.
        players[playerIndex].hand.removeAll { c in cards.contains(where: { $0.id == c.id }) }
        players[playerIndex].hasPlayed = true
        tableCombo = combo
        lastPlayerToPlay = playerIndex
        passStreak = 0
        log(String(format: L("log.played"), players[playerIndex].name, combo.cards.map { $0.label }.joined(separator: " ")))

        if players[playerIndex].hand.isEmpty {
            finishPlayer(playerIndex)
            return true
        }

        advanceTurn()
        return true
    }

    func pass(playerIndex: Int) {
        guard playerIndex == currentTurnIndex, tableCombo != nil else { return }
        log(String(format: L("log.passed"), players[playerIndex].name))
        passStreak += 1
        advanceTurn()

        let stillIn = players.filter { !$0.isFinished }
        if let last = lastPlayerToPlay, passStreak >= stillIn.count - 1, stillIn.contains(where: { $0.id == last }) {
            // Trick clears back to whoever played last — they lead a fresh trick.
            tableCombo = nil
            passStreak = 0
            currentTurnIndex = last
            log(String(format: L("log.leads"), players[currentTurnIndex].name))
        }
        maybeTriggerAI()
    }

    private func finishPlayer(_ index: Int) {
        let rank = players.filter { $0.isFinished }.count + 1
        players[index].finishedRank = rank

        let remaining = players.filter { !$0.isFinished }
        if remaining.count <= 1 || rank == 1 {
            // First player out ends the round in this ruleset.
            endRound(winner: index)
        } else {
            advanceTurn()
        }
    }

    private func advanceTurn() {
        var next = (currentTurnIndex + 1) % 4
        var guardCount = 0
        while players[next].isFinished && guardCount < 4 {
            next = (next + 1) % 4
            guardCount += 1
        }
        currentTurnIndex = next
        maybeTriggerAI()
    }

    // MARK: - Scoring

    private func endRound(winner: Int) {
        roundOver = true
        roundsWon[winner] += 1
        congIndices = []

        for i in 0..<4 where i != winner {
            var penalty = players[i].hand.reduce(0) { $0 + $1.pointValue } * GameModel.stakeUnit
            let unplayedTwos = players[i].hand.filter { $0.rank == .two }.count
            if unplayedTwos > 0 { penalty *= (1 + unplayedTwos) } // "thối heo" — holding 2s doubles the sting
            if players[i].hand.count == 4, Set(players[i].hand.map { $0.rank }).count == 1 {
                penalty *= 3 // held an entire unplayed tứ quý
            }
            if !players[i].hasPlayed {
                // "Cóng" — never got to play a single card by the time the round ended.
                // Stacks multiplicatively on top of the other penalties.
                penalty *= 3
                congIndices.append(i)
                log(String(format: L("log.congPenalty"), players[i].name))
            }
            matchScores[winner] += penalty
            matchScores[i] -= penalty
        }

        log(String(format: L("log.roundWinner"), players[winner].name))
        checkMatchEnd()
    }

    private func settleInstantWin(winner: Int, kind: InstantWinKind) {
        roundOver = true
        roundsWon[winner] += 1
        for i in 0..<4 where i != winner {
            let amount = kind.payoutMultiplier * GameModel.stakeUnit
            matchScores[winner] += amount
            matchScores[i] -= amount
        }
        log(String(format: L("log.instantWin"), players[winner].name, L(kind.titleKey)))
        checkMatchEnd()
    }

    private func checkMatchEnd() {
        roundNumber += 1
        if roundsWon.contains(where: { $0 >= matchTarget }) {
            matchOver = true
        }
    }

    private func log(_ message: String) {
        roundLog.append(message)
    }

    // MARK: - AI

    private func maybeTriggerAI() {
        guard !roundOver, !matchOver else { return }
        guard !currentPlayer.isHuman else { return }
        let index = currentTurnIndex
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run { self.runAITurn(index) }
        }
    }

    private func runAITurn(_ index: Int) {
        guard index == currentTurnIndex, !players[index].isFinished else { return }
        let hand = players[index].hand
        if let move = AIPlayer.chooseMove(hand: hand, mustBeat: tableCombo, difficulty: difficulty) {
            _ = play(playerIndex: index, cards: move.cards)
        } else {
            pass(playerIndex: index)
        }
    }
}
