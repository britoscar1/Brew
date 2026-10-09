//
//  BrewSettingsCard.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 26/09/26.
//

import SwiftUI

struct BrewSetting {
    let title: String
    let value: String
    let icon: String

    static func grams(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1)))) g"
    }

    static func duration(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0, seconds < Double(Int.max) else { return "—" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func all(for brew: Brew, recommendation: BrewRecommendation? = nil) -> [BrewSetting] {
        let changed = recommendation?.variable
        let showAll = changed == nil || changed == RecommendationVariable.none
        var items = [BrewSetting(title: String(localized: "Coffee"),
                                 value: grams(brew.coffeeGrams), icon: "scalemass")]

        if showAll || changed != .water, let water = brew.waterGrams {
            items.append(BrewSetting(title: String(localized: "Water"),
                                     value: grams(water), icon: "drop"))
        }

        if showAll || changed != .beverageYield, let beverage = brew.beverageGrams {
            items.append(BrewSetting(title: String(localized: "Beverage"),
                                     value: grams(beverage), icon: "cup.and.saucer"))
        }

        if showAll || changed != .grind {
            items.append(BrewSetting(title: String(localized: "Grind"),
                                     value: brew.grindDisplayValue, icon: "dial.medium"))
        }

        if let temperature = brew.temperatureCelsius {
            items.append(BrewSetting(
                title: String(localized: "Temperature"),
                value: "\(temperature.formatted(.number.precision(.fractionLength(0...1)))) °C",
                icon: "thermometer.medium"))
        }

        return items
    }
}

struct BrewSettingsCard: View {
    let settings: [BrewSetting]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(settings.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    Label(item.title, systemImage: item.icon)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(item.value)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.title)
                .accessibilityValue(item.value)

                if index < settings.count - 1 {
                    Divider()
                        .padding(.leading, 18)
                }
            }
        }
        .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
    }
}
