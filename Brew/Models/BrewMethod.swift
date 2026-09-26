//
//  BrewMethod.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import Foundation

enum BrewMethod: String, CaseIterable, Identifiable {
    case v60, aeroPress, frenchPress, espresso

    var id: String { rawValue }

    var title: String {
        switch self {
        case .v60: String(localized: "V60")
        case .aeroPress: String(localized: "AeroPress")
        case .frenchPress: String(localized: "French Press")
        case .espresso: String(localized: "Espresso")
        }
    }

    var iconName: String {
        switch self {
        case .v60: "V60Duotone"
        case .aeroPress: "AeroPressDuotone"
        case .frenchPress: "FrenchPressDuotone"
        case .espresso: "EspressoDuotone"
        }
    }

    var defaults: (coffeeGrams: Double, waterGrams: Double?, beverageGrams: Double?, temperatureCelsius: Double) {
        switch self {
        case .v60: (15, 250, nil, 94)
        case .aeroPress: (16, 240, nil, 88)
        case .frenchPress: (30, 500, nil, 95)
        case .espresso: (18, nil, 36, 93)
        }
    }

    var defaultRatio: Double {
        let yield = defaults.waterGrams ?? defaults.beverageGrams ?? 0
        return yield / defaults.coffeeGrams
    }
}
