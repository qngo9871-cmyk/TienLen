import SwiftUI

struct UpgradeView: View {
    @StateObject private var purchases = PurchaseManager.shared
    @AppStorage("cardBackStyle") private var cardBackStyleRaw: String = CardBackStyle.classic.rawValue
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.15, green: 0.05, blue: 0.25), .black],
                                startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                VStack(spacing: 22) {
                    Text("👑").font(.system(size: 50))
                    Text(L("upgrade.title")).font(.title.bold()).foregroundStyle(.white)
                    Text(L("upgrade.subtitle")).font(.subheadline).foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center).padding(.horizontal, 30)

                    VStack(alignment: .leading, spacing: 12) {
                        featureRow("brain.head.profile", L("upgrade.feature.hardAI"))
                        featureRow("sparkles", L("upgrade.feature.cardBacks"))
                        featureRow("infinity", L("upgrade.feature.unlimited"))
                    }
                    .padding(.horizontal, 30)

                    if purchases.isPro {
                        Text(L("upgrade.owned")).foregroundStyle(.green).font(.headline)
                        cardBackPicker
                    } else {
                        Button {
                            Task { await purchases.purchase() }
                        } label: {
                            if purchases.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(purchases.product?.displayPrice.isEmpty == false
                                     ? String(format: L("upgrade.buy"), purchases.product!.displayPrice)
                                     : L("upgrade.buyFallback"))
                                    .font(.title3.bold()).frame(maxWidth: 260).padding()
                            }
                        }
                        .buttonStyle(.borderedProminent).tint(.purple)
                        .disabled(purchases.isPurchasing)

                        Button(L("upgrade.restore")) { Task { await purchases.restorePurchases() } }
                            .font(.footnote).foregroundStyle(.white.opacity(0.6))

                        if let err = purchases.purchaseError {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }

                    Button(L("upgrade.close")) { dismiss() }
                        .foregroundStyle(.white.opacity(0.5)).padding(.top, 6)
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.purple).frame(width: 24)
            Text(text).foregroundStyle(.white)
        }
    }

    private var cardBackPicker: some View {
        VStack(spacing: 10) {
            Text(L("upgrade.cardBack.title")).font(.subheadline.bold()).foregroundStyle(.white.opacity(0.85))
            HStack(spacing: 16) {
                ForEach(CardBackStyle.allCases) { style in
                    Button { cardBackStyleRaw = style.rawValue } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(colors: style.gradientColors,
                                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 46, height: 67)
                                .overlay(Image(systemName: style.icon).foregroundStyle(.white.opacity(0.4)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(cardBackStyleRaw == style.rawValue ? Color.yellow : Color.clear, lineWidth: 3)
                                )
                            Text(L(style.titleKey)).font(.caption2).foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}

#Preview { UpgradeView() }
