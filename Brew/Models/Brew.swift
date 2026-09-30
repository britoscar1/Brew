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
    var statusRawValue: String = BrewStatus.completed.rawValue
    var createdAt: Date = Date.now
    var startedAt: Date?
    var pausedAt: Date?
    var accumulatedPausedSeconds: Double = 0
    var targetDurationSeconds: Double?
    var completedAt: Date?
    var actualDurationSeconds: Double?

    @Relationship(deleteRule: .cascade, inverse: \TasteEvaluation.brew)
    var tasteEvaluation: TasteEvaluation?

    @Relationship(deleteRule: .cascade, inverse: \BrewRecommendation.brew)
    var recommendation: BrewRecommendation?

    var status: BrewStatus {
        get { BrewStatus(rawValue: statusRawValue) ?? .completed }
        set { statusRawValue = newValue.rawValue }
    }

    var sortDate: Date {
        completedAt ?? createdAt
    }

    var method: BrewMethod? {
        BrewMethod(rawValue: methodRawValue)
    }

    var ratio: Double? {
        let yield = method == .espresso ? beverageGrams : waterGrams
        guard let yield, coffeeGrams > 0 else { return nil }
        return yield / coffeeGrams
    }

    init(coffee: Coffee, method: BrewMethod, coffeeGrams: Double,
         grindDisplayValue: String, status: BrewStatus = .draft,
         createdAt: Date = .now, completedAt: Date? = nil,
         waterGrams: Double? = nil, beverageGrams: Double? = nil,
         temperatureCelsius: Double? = nil, targetDurationSeconds: Double? = nil,
         actualDurationSeconds: Double? = nil) {
        self.coffee = coffee
        methodRawValue = method.rawValue
        self.coffeeGrams = coffeeGrams
        self.grindDisplayValue = grindDisplayValue
        statusRawValue = status.rawValue
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.waterGrams = waterGrams
        self.beverageGrams = beverageGrams
        self.temperatureCelsius = temperatureCelsius
        self.targetDurationSeconds = targetDurationSeconds
        self.actualDurationSeconds = actualDurationSeconds
    }
}
