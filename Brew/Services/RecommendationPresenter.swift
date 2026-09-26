//
//  RecommendationPresenter.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import Foundation

struct RecommendationPresentation {
    let previousDisplayValue: String?
    let suggestedDisplayValue: String?
    let explanation: String
}

struct RecommendationPresenter {
    func present(_ decision: RecommendationDecision) -> RecommendationPresentation {
        RecommendationPresentation(
            previousDisplayValue: decision.previousValue.map(displayValue),
            suggestedDisplayValue: decision.suggestedValue.map(displayValue),
            explanation: explanation(for: decision)
        )
    }

    private func displayValue(_ value: RecommendationValue) -> String {
        switch value {
        case let .text(text):
            text
        case let .grams(grams):
            "\(grams.formatted(.number.precision(.fractionLength(0...1)))) g"
        }
    }

    private func explanation(for decision: RecommendationDecision) -> String {
        switch decision.direction {
        case .finer where decision.ruleID == .goalAcidStrong:
            String(localized: "This brew already tasted strong, so change the grind only slightly and see how the next cup lands. Keep everything else the same.")
        case .finer:
            String(localized: "This brew leaned acidic. A slightly finer grind may increase extraction. Keep the coffee amount, water and temperature unchanged.")
        case .coarser:
            String(localized: "This brew leaned bitter. A slightly coarser grind may reduce extraction. Keep the other settings unchanged.")
        case .decrease where decision.variable == .water:
            String(localized: "This brew tasted weaker than you wanted. Try slightly less water while keeping the coffee dose, grind and temperature unchanged.")
        case .increase where decision.variable == .water:
            String(localized: "This brew tasted stronger than you wanted. Try slightly more water while keeping the coffee dose, grind and temperature unchanged.")
        case .decrease where decision.variable == .beverageYield:
            String(localized: "This espresso tasted weaker than you wanted. Try a slightly smaller beverage yield while keeping the dose and grind unchanged.")
        case .increase where decision.variable == .beverageYield:
            String(localized: "This espresso tasted stronger than you wanted. Try a slightly larger beverage yield while keeping the dose and grind unchanged.")
        case .maintain:
            String(localized: "You enjoyed this brew. Keep the current settings so you can reproduce it.")
        case .unclear where decision.ruleID == .conflictingTaste || decision.ruleID == .goalBitterWeak:
            String(localized: "Your feedback points in more than one direction, so there isn't one clear adjustment to recommend. Try repeating the brew once more before changing the recipe.")
        default:
            String(localized: "There isn't one clear adjustment based on this evaluation. Try repeating the brew once more before changing the recipe.")
        }
    }
}
