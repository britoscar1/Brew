//
//  RecommendationInput+Brew.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 01/10/26.
//

import Foundation

extension RecommendationInput {
    init(brew: Brew, acidity: Int, bitterness: Int, strength: Int,
         overall: Int, goal: ImprovementGoal?) {
        self.init(
            acidity: acidity,
            bitterness: bitterness,
            strength: strength,
            overall: overall,
            goal: goal,
            method: brew.method ?? .v60,
            waterGrams: brew.waterGrams,
            beverageGrams: brew.beverageGrams,
            grindDisplayValue: brew.grindDisplayValue
        )
    }

    init(brew: Brew, evaluation: TasteEvaluation) {
        self.init(
            brew: brew,
            acidity: evaluation.acidityValue,
            bitterness: evaluation.bitternessValue,
            strength: evaluation.strengthValue,
            overall: evaluation.overallValue,
            goal: evaluation.improvementGoal
        )
    }
}
