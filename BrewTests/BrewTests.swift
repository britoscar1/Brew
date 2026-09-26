//
//  BrewTests.swift
//  BrewTests
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import Testing
import Foundation
import SwiftData
@testable import Brew

private func input(acidity: Int = 3, bitterness: Int = 3, strength: Int = 3, overall: Int = 3,
                   goal: ImprovementGoal? = nil, method: BrewMethod = .v60,
                   water: Double? = 250, beverage: Double? = nil,
                   grind: String = "Medium") -> RecommendationInput {
    RecommendationInput(acidity: acidity, bitterness: bitterness, strength: strength,
                        overall: overall, goal: goal, method: method,
                        waterGrams: water, beverageGrams: beverage, grindDisplayValue: grind)
}

private let engine = RecommendationEngine()

private func grams(from value: RecommendationValue?) -> Double? {
    guard case let .grams(grams) = value else { return nil }
    return grams
}

private func text(from value: RecommendationValue?) -> String? {
    guard case let .text(text) = value else { return nil }
    return text
}

@Test func sourAndWeakSuggestsFinerGrind() {
    let decision = engine.recommend(for: input(acidity: 5, strength: 2, overall: 2))
    #expect(decision?.ruleID == .automaticSourWeak)
    #expect(decision?.variable == .grind)
    #expect(decision?.direction == .finer)
}

@Test func bitterAndStrongSuggestsCoarserGrind() {
    let decision = engine.recommend(for: input(bitterness: 5, strength: 5, overall: 2))
    #expect(decision?.ruleID == .automaticBitterStrong)
    #expect(decision?.direction == .coarser)
}

@Test func strongerGoalOnWeakManualReducesWater() {
    let decision = engine.recommend(for: input(strength: 1, goal: .stronger, water: 250))
    #expect(decision?.ruleID == .goalStrongerManual)
    #expect(decision?.variable == .water)
    #expect(grams(from: decision?.previousValue) == 250)
    #expect(grams(from: decision?.suggestedValue) == 240)
}

@Test func strongerGoalOnWeakEspressoLowersYield() {
    let decision = engine.recommend(for: input(strength: 1, goal: .stronger, method: .espresso,
                                               water: nil, beverage: 36))
    #expect(decision?.ruleID == .goalStrongerEspresso)
    #expect(decision?.variable == .beverageYield)
    #expect(grams(from: decision?.suggestedValue) == 34)
}

@Test func weakerGoalOnStrongManualAddsWater() {
    let decision = engine.recommend(for: input(strength: 5, goal: .weaker, water: 250))
    #expect(decision?.ruleID == .goalWeakerManual)
    #expect(grams(from: decision?.suggestedValue) == 265)
}

@Test func weakerGoalOnStrongEspressoRaisesYield() {
    let decision = engine.recommend(for: input(strength: 5, goal: .weaker, method: .espresso,
                                               water: nil, beverage: 36))
    #expect(decision?.ruleID == .goalWeakerEspresso)
    #expect(grams(from: decision?.suggestedValue) == 38)
}

@Test func keepAsIsAlwaysMaintains() {
    let decision = engine.recommend(for: input(acidity: 5, bitterness: 1, strength: 5,
                                               overall: 1, goal: .keepAsIs))
    #expect(decision?.ruleID == .keepExplicit)
    #expect(decision?.direction == .maintain)
}

@Test func highAcidityAndHighBitternessIsUnclear() {
    let decision = engine.recommend(for: input(acidity: 5, bitterness: 5, overall: 2))
    #expect(decision?.ruleID == .conflictingTaste)
    #expect(decision?.direction == .unclear)
}

@Test func lessAcidicGoalWithLowAcidityIsUnclear() {
    let decision = engine.recommend(for: input(acidity: 1, goal: .lessAcidic))
    #expect(decision?.ruleID == .goalAcidMismatch)
    #expect(decision?.direction == .unclear)
}

@Test func positiveOverallWithoutGoalMaintains() {
    let decision = engine.recommend(for: input(acidity: 4, strength: 2, overall: 5))
    #expect(decision?.ruleID == .automaticPositive)
    #expect(decision?.direction == .maintain)
}

@Test func grindSuggestionStaysQualitative() {
    let decision = engine.recommend(for: input(acidity: 5, strength: 2, overall: 2, grind: "22 clicks"))
    #expect(text(from: decision?.previousValue) == "22 clicks")
    #expect(decision?.suggestedValue == nil)
}

@Test func sameInputProducesSameDecision() {
    let sample = input(acidity: 5, strength: 2, overall: 2)
    let first = engine.recommend(for: sample)
    let second = engine.recommend(for: sample)
    #expect(first?.ruleID == second?.ruleID)
    #expect(first?.variable == second?.variable)
    #expect(first?.direction == second?.direction)
    let firstPresentation = first.map { RecommendationPresenter().present($0) }
    let secondPresentation = second.map { RecommendationPresenter().present($0) }
    #expect(firstPresentation?.suggestedDisplayValue == secondPresentation?.suggestedDisplayValue)
}

@Test func everyDecisionChangesAtMostOneVariable() {
    let goals: [ImprovementGoal?] = [nil] + ImprovementGoal.allCases.map { $0 }
    for acidity in 1...5 {
        for bitterness in 1...5 {
            for strength in 1...5 {
                for overall in 1...5 {
                    for goal in goals {
                        let decision = engine.recommend(for: input(acidity: acidity, bitterness: bitterness,
                                                                   strength: strength, overall: overall, goal: goal))
                        #expect(decision != nil)
                        if decision?.variable == RecommendationVariable.none {
                            #expect(decision?.suggestedValue == nil)
                        }
                    }
                }
            }
        }
    }
}

@Test func valuesOutsideTheScaleProduceNoRecommendation() {
    #expect(engine.recommend(for: input(acidity: 0)) == nil)
    #expect(engine.recommend(for: input(overall: 6)) == nil)
}

@Test func missingAmountFallsBackToUnclearRatherThanSilence() {
    #expect(engine.recommend(for: input(strength: 1, goal: .stronger, water: nil))?.direction == .unclear)
    #expect(engine.recommend(for: input(strength: 5, goal: .weaker, method: .espresso,
                                        water: nil, beverage: nil))?.direction == .unclear)
}

@Test func presenterFormatsDecisionWithoutChangingEngineLogic() {
    let decision = engine.recommend(for: input(strength: 1, goal: .stronger, water: 250))
    let presentation = decision.map { RecommendationPresenter().present($0) }

    #expect(presentation?.previousDisplayValue == "250 g")
    #expect(presentation?.suggestedDisplayValue == "240 g")
    #expect(presentation?.explanation.isEmpty == false)
}

@Test func editingEvaluationReplacesPersistedRecommendation() async throws {
    try await MainActor.run {
        let schema = Schema([
            Coffee.self,
            Brew.self,
            TasteEvaluation.self,
            BrewRecommendation.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        let coffee = Coffee(name: "Test Coffee", origin: "Test Origin", roastLevel: .medium)
        let brew = Brew(
            coffee: coffee,
            method: .v60,
            coffeeGrams: 15,
            grindDisplayValue: "Medium",
            completedAt: .now,
            waterGrams: 250
        )
        context.insert(coffee)
        context.insert(brew)

        let evaluation = TasteEvaluationViewModel(brew: brew)
        evaluation.acidityValue = 5
        evaluation.strengthValue = 2
        evaluation.overallValue = 2
        let firstSaveSucceeded = evaluation.save(in: context)
        #expect(firstSaveSucceeded)
        #expect(brew.recommendation?.ruleID == "AUTO_SOUR_WEAK")

        evaluation.acidityValue = 3
        evaluation.strengthValue = 1
        evaluation.improvementGoal = .stronger
        let secondSaveSucceeded = evaluation.save(in: context)
        #expect(secondSaveSucceeded)

        let recommendations = try context.fetch(FetchDescriptor<BrewRecommendation>())
        #expect(recommendations.count == 1)
        #expect(brew.recommendation?.ruleID == "GOAL_STRONGER_MANUAL")
    }
}
