//
//  RecommendationTypes.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import Foundation

enum RecommendationVariable: String {
    case grind, water, beverageYield, none

    var title: String {
        switch self {
        case .grind: String(localized: "Grind")
        case .water: String(localized: "Water")
        case .beverageYield: String(localized: "Beverage yield")
        case .none: String(localized: "Recipe")
        }
    }
}

enum RecommendationDirection: String {
    case finer, coarser, increase, decrease, maintain, unclear

    var title: String {
        switch self {
        case .finer: String(localized: "Grind finer")
        case .coarser: String(localized: "Grind coarser")
        case .increase: String(localized: "Increase")
        case .decrease: String(localized: "Decrease")
        case .maintain: String(localized: "Keep as is")
        case .unclear: String(localized: "No clear change")
        }
    }
}

enum RecommendationRuleID: String {
    case invalidInput = "CTRL_INVALID_INPUT"
    case keepExplicit = "CTRL_KEEP_EXPLICIT"
    case conflictingTaste = "CTRL_CONFLICT_TASTE"

    case goalAcidWeak = "GOAL_ACID_WEAK"
    case goalAcidBalanced = "GOAL_ACID_BALANCED"
    case goalAcidStrong = "GOAL_ACID_STRONG"
    case goalAcidMismatch = "GOAL_ACID_MISMATCH"

    case goalBitterStrong = "GOAL_BITTER_STRONG"
    case goalBitterBalanced = "GOAL_BITTER_BALANCED"
    case goalBitterWeak = "GOAL_BITTER_WEAK"
    case goalBitterMismatch = "GOAL_BITTER_MISMATCH"

    case goalStrongerAcid = "GOAL_STRONGER_ACID"
    case goalStrongerManual = "GOAL_STRONGER_MANUAL"
    case goalStrongerEspresso = "GOAL_STRONGER_ESPRESSO"
    case goalStrongerMismatch = "GOAL_STRONGER_MISMATCH"
    case goalStrongerUnclear = "GOAL_STRONGER_UNCLEAR"

    case goalWeakerBitter = "GOAL_WEAKER_BITTER"
    case goalWeakerManual = "GOAL_WEAKER_MANUAL"
    case goalWeakerEspresso = "GOAL_WEAKER_ESPRESSO"
    case goalWeakerMismatch = "GOAL_WEAKER_MISMATCH"
    case goalWeakerUnclear = "GOAL_WEAKER_UNCLEAR"

    case automaticSourWeak = "AUTO_SOUR_WEAK"
    case automaticSourBalanced = "AUTO_SOUR_BALANCED"
    case automaticBitterStrong = "AUTO_BITTER_STRONG"
    case automaticBitterBalanced = "AUTO_BITTER_BALANCED"
    case automaticWeakManual = "AUTO_WEAK_MANUAL"
    case automaticWeakEspresso = "AUTO_WEAK_ESPRESSO"
    case automaticStrongManual = "AUTO_STRONG_MANUAL"
    case automaticStrongEspresso = "AUTO_STRONG_ESPRESSO"
    case automaticBalancedOkay = "AUTO_BALANCED_OKAY"
    case automaticPositive = "AUTO_POSITIVE"
    case automaticUnclear = "AUTO_UNCLEAR"
}

func recommendationHeadline(variable: RecommendationVariable?,
                            direction: RecommendationDirection?) -> String {
    guard let direction else { return "" }

    switch direction {
    case .finer, .coarser, .maintain, .unclear:
        return direction.title
    case .increase, .decrease:
        let variable = variable?.title ?? ""
        return direction == .increase
            ? String(localized: "More \(variable.lowercased())")
            : String(localized: "Less \(variable.lowercased())")
    }
}

enum RecommendationValue {
    case text(String)
    case grams(Double)
}
