//
//  TasteEvaluation.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import Foundation
import SwiftData

@Model
final class TasteEvaluation {
    var brew: Brew?
    var acidityValue: Int
    var bitternessValue: Int
    var strengthValue: Int
    var overallValue: Int
    var improvementGoalRawValue: String?
    var createdAt: Date
    var updatedAt: Date

    var improvementGoal: ImprovementGoal? {
        improvementGoalRawValue.flatMap(ImprovementGoal.init)
    }

    init(brew: Brew, acidityValue: Int, bitternessValue: Int,
         strengthValue: Int, overallValue: Int, improvementGoal: ImprovementGoal? = nil) {
        self.brew = brew
        self.acidityValue = acidityValue
        self.bitternessValue = bitternessValue
        self.strengthValue = strengthValue
        self.overallValue = overallValue
        improvementGoalRawValue = improvementGoal?.rawValue
        let now = Date()
        createdAt = now
        updatedAt = now
    }
}
