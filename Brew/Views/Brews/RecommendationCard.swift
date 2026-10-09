//
//  RecommendationCard.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 26/09/26.
//

import SwiftUI

struct RecommendationCard: View {
    let brew: Brew
    let recommendation: BrewRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                if let method = brew.method {
                    Image(method.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(brew.coffee?.name ?? String(localized: "Coffee"))
                        .font(.headline)

                    Text(brew.method?.title ?? String(localized: "Unknown method"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color("CoffeeTint"))
                    .frame(width: 44, height: 44)
                    .background(Color("CoffeeCanvas").opacity(0.75), in: Circle())
            }

            Divider()

            Text(headline)
                .font(.title2.weight(.semibold))

            if recommendation.direction != .maintain, recommendation.direction != .unclear {
                adjustmentValues
            }
        }
        .padding(20)
        .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color("CoffeeTint").opacity(0.12))
        }
    }

    private var adjustmentValues: some View {
        HStack(spacing: 12) {
            value(recommendation.previousDisplayValue ?? currentValue, color: .secondary)

            Image(systemName: "arrow.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            value(recommendation.suggestedDisplayValue ?? recommendation.direction?.title ?? "",
                  color: Color("CoffeeTint"))
        }
    }

    private func value(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title3.weight(.semibold))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(Color("CoffeeCanvas").opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
    }

    private var headline: String {
        recommendationHeadline(variable: recommendation.variable,
                               direction: recommendation.direction)
    }

    private var currentValue: String {
        switch recommendation.variable {
        case .water: brew.waterGrams.map(BrewSetting.grams) ?? "—"
        case .beverageYield: brew.beverageGrams.map(BrewSetting.grams) ?? "—"
        case .grind: brew.grindDisplayValue
        default: "—"
        }
    }

    private var icon: String {
        switch recommendation.direction {
        case .finer, .coarser: "dial.medium"
        case .increase: "arrow.up.circle"
        case .decrease: "arrow.down.circle"
        case .maintain: "checkmark.circle"
        default: "questionmark.circle"
        }
    }
}
