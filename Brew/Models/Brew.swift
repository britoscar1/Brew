//
//  Brew.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import Foundation
import SwiftData

@Model
class Brew {
    var coffee: Coffee?
    var methodRawValue: String
    var coffeeGrams: Double
    var waterGrams: Double?
    var beverageGrams: Double?
    var temperatureCelsius: Double?
    var grindDisplayValue: String
    var completedAt: Date
    var actualDurationSeconds: Double?

    @Relationship(deleteRule: .cascade, inverse: \TasteEvaluation.brew)
    var tasteEvaluation: TasteEvaluation?

    @Relationship(deleteRule: .cascade, inverse: \BrewRecommendation.brew)
    var recommendation: BrewRecommendation?

    var method: BrewMethod? {
        BrewMethod(rawValue: methodRawValue)
    }

    var ratio: Double? {
        let yield = method == .espresso ? beverageGrams : waterGrams
        guard let yield, coffeeGrams > 0 else { return nil }
        return yield / coffeeGrams
    }

    init(coffee: Coffee, method: BrewMethod, coffeeGrams: Double,
         grindDisplayValue: String, completedAt: Date,
         waterGrams: Double? = nil, beverageGrams: Double? = nil,
         temperatureCelsius: Double? = nil, actualDurationSeconds: Double? = nil) {
        self.coffee = coffee
        methodRawValue = method.rawValue
        self.coffeeGrams = coffeeGrams
        self.grindDisplayValue = grindDisplayValue
        self.completedAt = completedAt
        self.waterGrams = waterGrams
        self.beverageGrams = beverageGrams
        self.temperatureCelsius = temperatureCelsius
        self.actualDurationSeconds = actualDurationSeconds
    }
}
