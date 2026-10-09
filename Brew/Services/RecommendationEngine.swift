//
//  RecommendationEngine.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import Foundation

struct RecommendationInput {
    let acidity: Int
    let bitterness: Int
    let strength: Int
    let overall: Int
    let goal: ImprovementGoal?
    let method: BrewMethod
    let waterGrams: Double?
    let beverageGrams: Double?
    let grindDisplayValue: String
}

struct RecommendationDecision {
    let ruleID: RecommendationRuleID
    let variable: RecommendationVariable
    let direction: RecommendationDirection
    let previousValue: RecommendationValue?
    let suggestedValue: RecommendationValue?
    let rulesVersion: Int
}

struct RecommendationEngine {
    static let rulesVersion = 1

    func recommend(for input: RecommendationInput) -> RecommendationDecision? {
        guard isValid(input) else { return nil }

        if input.goal == .keepAsIs {
            return maintain(ruleID: .keepExplicit)
        }

        if input.acidity >= 4 && input.bitterness >= 4 {
            return unclear(ruleID: .conflictingTaste)
        }

        if let goal = input.goal {
            return goalDecision(for: goal, input: input)
        }

        return automaticDecision(for: input)
    }

    private func isValid(_ input: RecommendationInput) -> Bool {
        [input.acidity, input.bitterness, input.strength, input.overall]
            .allSatisfy { (1...5).contains($0) }
    }

    // MARK: Goal matrix

    private func goalDecision(for goal: ImprovementGoal, input: RecommendationInput) -> RecommendationDecision {
        switch goal {
        case .lessAcidic: lessAcidic(input)
        case .lessBitter: lessBitter(input)
        case .stronger: stronger(input)
        case .weaker: weaker(input)
        case .keepAsIs: maintain(ruleID: .keepExplicit)
        }
    }

    private func lessAcidic(_ input: RecommendationInput) -> RecommendationDecision {
        guard input.acidity >= 4 else {
            return unclear(ruleID: .goalAcidMismatch)
        }

        if input.strength <= 2 {
            return grind(.finer, ruleID: .goalAcidWeak, input: input)
        }
        if input.strength == 3 {
            return grind(.finer, ruleID: .goalAcidBalanced, input: input)
        }
        return grind(.finer, ruleID: .goalAcidStrong, input: input)
    }

    private func lessBitter(_ input: RecommendationInput) -> RecommendationDecision {
        guard input.bitterness >= 4 else {
            return unclear(ruleID: .goalBitterMismatch)
        }

        if input.strength >= 4 {
            return grind(.coarser, ruleID: .goalBitterStrong, input: input)
        }
        if input.strength == 3 {
            return grind(.coarser, ruleID: .goalBitterBalanced, input: input)
        }
        return unclear(ruleID: .goalBitterWeak)
    }

    private func stronger(_ input: RecommendationInput) -> RecommendationDecision {
        guard input.strength <= 2 else {
            return unclear(ruleID: .goalStrongerMismatch)
        }

        if input.acidity >= 4 {
            return grind(.finer, ruleID: .goalStrongerAcid, input: input)
        }
        if input.acidity <= 3 && input.bitterness <= 3 {
            return input.method == .espresso
                ? yield(.decrease, ruleID: .goalStrongerEspresso, input: input)
                : water(.decrease, ruleID: .goalStrongerManual, input: input)
        }
        return unclear(ruleID: .goalStrongerUnclear)
    }

    private func weaker(_ input: RecommendationInput) -> RecommendationDecision {
        guard input.strength >= 4 else {
            return unclear(ruleID: .goalWeakerMismatch)
        }

        if input.bitterness >= 4 {
            return grind(.coarser, ruleID: .goalWeakerBitter, input: input)
        }
        if input.acidity <= 3 && input.bitterness <= 3 {
            return input.method == .espresso
                ? yield(.increase, ruleID: .goalWeakerEspresso, input: input)
                : water(.increase, ruleID: .goalWeakerManual, input: input)
        }
        return unclear(ruleID: .goalWeakerUnclear)
    }

    // MARK: Automatic matrix

    private func automaticDecision(for input: RecommendationInput) -> RecommendationDecision {
        if input.overall >= 4 {
            return maintain(ruleID: .automaticPositive)
        }

        let acidityHigh = input.acidity >= 4
        let bitternessHigh = input.bitterness >= 4
        let mildTaste = input.acidity <= 3 && input.bitterness <= 3

        if acidityHigh && !bitternessHigh {
            if input.strength <= 2 {
                return grind(.finer, ruleID: .automaticSourWeak, input: input)
            }
            if input.strength == 3 {
                return grind(.finer, ruleID: .automaticSourBalanced, input: input)
            }
        }

        if bitternessHigh && !acidityHigh {
            if input.strength >= 4 {
                return grind(.coarser, ruleID: .automaticBitterStrong, input: input)
            }
            if input.strength == 3 {
                return grind(.coarser, ruleID: .automaticBitterBalanced, input: input)
            }
        }

        if mildTaste && input.strength <= 2 {
            return input.method == .espresso
                ? yield(.decrease, ruleID: .automaticWeakEspresso, input: input)
                : water(.decrease, ruleID: .automaticWeakManual, input: input)
        }

        if mildTaste && input.strength >= 4 {
            return input.method == .espresso
                ? yield(.increase, ruleID: .automaticStrongEspresso, input: input)
                : water(.increase, ruleID: .automaticStrongManual, input: input)
        }

        if input.acidity == 3 && input.bitterness == 3 && input.strength == 3 && input.overall == 3 {
            return maintain(ruleID: .automaticBalancedOkay)
        }

        return unclear(ruleID: .automaticUnclear)
    }

    // MARK: Outcomes

    private func grind(_ direction: RecommendationDirection, ruleID: RecommendationRuleID,
                       input: RecommendationInput) -> RecommendationDecision {
        RecommendationDecision(
            ruleID: ruleID,
            variable: .grind,
            direction: direction,
            previousValue: .text(input.grindDisplayValue),
            suggestedValue: nil,
            rulesVersion: Self.rulesVersion
        )
    }

    private func water(_ direction: RecommendationDirection, ruleID: RecommendationRuleID,
                       input: RecommendationInput) -> RecommendationDecision {
        guard let current = input.waterGrams, let target = adjusted(current, direction: direction, step: 5) else {
            return unclear(ruleID: ruleID)
        }

        return RecommendationDecision(
            ruleID: ruleID,
            variable: .water,
            direction: direction,
            previousValue: .grams(current),
            suggestedValue: .grams(target),
            rulesVersion: Self.rulesVersion
        )
    }

    private func yield(_ direction: RecommendationDirection, ruleID: RecommendationRuleID,
                       input: RecommendationInput) -> RecommendationDecision {
        guard let current = input.beverageGrams, let target = adjusted(current, direction: direction, step: 1) else {
            return unclear(ruleID: ruleID)
        }

        return RecommendationDecision(
            ruleID: ruleID,
            variable: .beverageYield,
            direction: direction,
            previousValue: .grams(current),
            suggestedValue: .grams(target),
            rulesVersion: Self.rulesVersion
        )
    }

    private func maintain(ruleID: RecommendationRuleID) -> RecommendationDecision {
        RecommendationDecision(
            ruleID: ruleID,
            variable: .none,
            direction: .maintain,
            previousValue: nil,
            suggestedValue: nil,
            rulesVersion: Self.rulesVersion
        )
    }

    private func unclear(ruleID: RecommendationRuleID) -> RecommendationDecision {
        RecommendationDecision(
            ruleID: ruleID,
            variable: .none,
            direction: .unclear,
            previousValue: nil,
            suggestedValue: nil,
            rulesVersion: Self.rulesVersion
        )
    }

    private func adjusted(_ value: Double, direction: RecommendationDirection, step: Double) -> Double? {
        guard value.isFinite, value > 0 else { return nil }
        let factor = direction == .decrease ? 0.95 : 1.05
        var target = (value * factor / step).rounded() * step
        // Even small doses must move in the direction named by the advice.
        if direction == .decrease, target >= value { target -= step }
        if direction == .increase, target <= value { target += step }
        return target.isFinite && target > 0 ? target : nil
    }
}
