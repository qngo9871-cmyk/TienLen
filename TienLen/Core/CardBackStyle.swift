import SwiftUI

/// Card back designs shown face-down (opponents' hands). "classic" is free; the other two
/// are the "Exclusive card back designs" Pro feature advertised in UpgradeView — this enum
/// is what actually implements that promise (previously advertised but never built).
enum CardBackStyle: String, CaseIterable, Identifiable {
    case classic, royal, jade

    var id: String { rawValue }

    var isProOnly: Bool { self != .classic }

    var titleKey: String {
        switch self {
        case .classic: return "cardback.classic"
        case .royal: return "cardback.royal"
        case .jade: return "cardback.jade"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .classic: return [Color(red: 0.6, green: 0.05, blue: 0.05), Color(red: 0.3, green: 0.02, blue: 0.02)]
        case .royal: return [Color(red: 0.08, green: 0.14, blue: 0.5), Color(red: 0.02, green: 0.04, blue: 0.22)]
        case .jade: return [Color(red: 0.02, green: 0.38, blue: 0.24), Color(red: 0.01, green: 0.16, blue: 0.11)]
        }
    }

    var icon: String {
        switch self {
        case .classic: return "suit.club.fill"
        case .royal: return "star.fill"
        case .jade: return "leaf.fill"
        }
    }
}
