//
//  BrewAdjustment.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 01/10/26.
//

import Foundation

struct BrewAdjustment {
    let variable: RecommendationVariable
    let direction: RecommendationDirection
    let previousDisplayValue: String
    let suggestedGrams: Double?

    init?(decision: RecommendationDecision, brew: Brew) {
        switch decision.direction {
        case .maintain, .unclear:
            return nil
        case .finer, .coarser, .increase, .decrease:
            break
        }

        switch decision.variable {
        case .grind:
            previousDisplayValue = brew.grindDisplayValue
            suggestedGrams = nil
        case .water:
            guard let water = brew.waterGrams,
                  let suggested = grams(from: decision.suggestedValue) else { return nil }
            previousDisplayValue = display(water)
            suggestedGrams = suggested
        case .beverageYield:
            guard let beverage = brew.beverageGrams,
                  let suggested = grams(from: decision.suggestedValue) else { return nil }
            previousDisplayValue = display(beverage)
            suggestedGrams = suggested
        case .none:
            return nil
        }

        variable = decision.variable
        direction = decision.direction
    }

    init?(brew: Brew) {
        guard let evaluation = brew.tasteEvaluation else { return nil }

        let input = RecommendationInput(brew: brew, evaluation: evaluation)

        guard let decision = RecommendationEngine().recommend(for: input) else { return nil }

        self.init(decision: decision, brew: brew)
    }
}

private func grams(from value: RecommendationValue?) -> Double? {
    guard case let .grams(grams) = value else { return nil }
    return grams
}

private func display(_ grams: Double) -> String {
    "\(grams.formatted(.number.precision(.fractionLength(0...1)))) g"
}
