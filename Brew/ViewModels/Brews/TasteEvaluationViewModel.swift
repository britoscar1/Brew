//
//  TasteEvaluationViewModel.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TasteEvaluationViewModel {
    private let brew: Brew

    var acidityValue = 3
    var bitternessValue = 3
    var strengthValue = 3
    var overallValue = 3
    var improvementGoal: ImprovementGoal?

    init(brew: Brew) {
        self.brew = brew

        guard let evaluation = brew.tasteEvaluation else { return }

        acidityValue = evaluation.acidityValue
        bitternessValue = evaluation.bitternessValue
        strengthValue = evaluation.strengthValue
        overallValue = evaluation.overallValue
        improvementGoal = evaluation.improvementGoal
    }

    var isEditing: Bool {
        brew.tasteEvaluation != nil
    }

    func save(in context: ModelContext) -> Bool {
        if let evaluation = brew.tasteEvaluation {
            evaluation.acidityValue = acidityValue
            evaluation.bitternessValue = bitternessValue
            evaluation.strengthValue = strengthValue
            evaluation.overallValue = overallValue
            evaluation.improvementGoalRawValue = improvementGoal?.rawValue
            evaluation.updatedAt = .now
        } else {
            let evaluation = TasteEvaluation(
                brew: brew,
                acidityValue: acidityValue,
                bitternessValue: bitternessValue,
                strengthValue: strengthValue,
                overallValue: overallValue,
                improvementGoal: improvementGoal
            )
            context.insert(evaluation)
        }

        let input = RecommendationInput(
            acidity: acidityValue,
            bitterness: bitternessValue,
            strength: strengthValue,
            overall: overallValue,
            goal: improvementGoal,
            method: brew.method ?? .v60,
            waterGrams: brew.waterGrams,
            beverageGrams: brew.beverageGrams,
            grindDisplayValue: brew.grindDisplayValue
        )

        if let decision = RecommendationEngine().recommend(for: input) {
            if let recommendation = brew.recommendation {
                recommendation.update(with: decision)
            } else {
                context.insert(BrewRecommendation(brew: brew, decision: decision))
            }
        } else if let recommendation = brew.recommendation {
            context.delete(recommendation)
        }

        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
}
