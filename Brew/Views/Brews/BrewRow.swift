//
//  BrewRow.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import SwiftUI

struct BrewRow: View {
    let brew: Brew

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let rank = brew.topBrewRank {
                    Text("#\(rank)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("CoffeeTint"))
                        .accessibilityLabel("Top 3, position \(rank)")
                }

                Text(brew.method?.title ?? String(localized: "Unknown method"))
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(brew.sortDate, format: .dateTime.month(.abbreviated).day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let evaluation = brew.tasteEvaluation {
                RatingDots(value: evaluation.overallValue)
            }

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var summary: String {
        var parts = ["\(brew.coffeeGrams.formatted(.number.precision(.fractionLength(0...1)))) g"]

        if let ratio = brew.ratio {
            parts.append("1:\(ratio.formatted(.number.precision(.fractionLength(1))))")
        }

        if let temperature = brew.temperatureCelsius {
            parts.append("\(temperature.formatted(.number.precision(.fractionLength(0)))) °C")
        }

        parts.append(brew.grindDisplayValue)

        return parts.joined(separator: " · ")
    }
}

private struct RatingDots: View {
    let value: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { step in
                Circle()
                    .fill(Color("CoffeeTint").opacity(step <= value ? 1 : 0.15))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue("\(value) of 5")
    }
}
