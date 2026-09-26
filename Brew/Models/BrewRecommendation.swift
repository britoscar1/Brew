//
//  BrewRecommendation.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import Foundation
import SwiftData

@Model
final class BrewRecommendation {
    var brew: Brew?
    var variableRawValue: String
    var directionRawValue: String
    var previousDisplayValue: String?
    var suggestedDisplayValue: String?
    var explanation: String
    var ruleID: String
    var rulesVersion: Int
    var createdAt: Date

    var variable: RecommendationVariable? {
        RecommendationVariable(rawValue: variableRawValue)
    }

    var direction: RecommendationDirection? {
        RecommendationDirection(rawValue: directionRawValue)
    }

    init(brew: Brew, decision: RecommendationDecision) {
        let presentation = RecommendationPresenter().present(decision)

        self.brew = brew
        variableRawValue = decision.variable.rawValue
        directionRawValue = decision.direction.rawValue
        previousDisplayValue = presentation.previousDisplayValue
        suggestedDisplayValue = presentation.suggestedDisplayValue
        explanation = presentation.explanation
        ruleID = decision.ruleID.rawValue
        rulesVersion = decision.rulesVersion
        createdAt = Date()
    }

    func update(with decision: RecommendationDecision) {
        let presentation = RecommendationPresenter().present(decision)

        variableRawValue = decision.variable.rawValue
        directionRawValue = decision.direction.rawValue
        previousDisplayValue = presentation.previousDisplayValue
        suggestedDisplayValue = presentation.suggestedDisplayValue
        explanation = presentation.explanation
        ruleID = decision.ruleID.rawValue
        rulesVersion = decision.rulesVersion
        createdAt = Date()
    }
}
