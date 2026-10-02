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
            status: .completed,
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

private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
private let timer = BrewTimerEngine()

private func elapsed(_ status: BrewStatus, started: Date? = t0, paused: Date? = nil,
                     accumulated: Double = 0, actual: Double? = nil, at seconds: Double) -> Double {
    timer.elapsedSeconds(status: status, startedAt: started, pausedAt: paused,
                         accumulatedPausedSeconds: accumulated, actualDurationSeconds: actual,
                         now: t0.addingTimeInterval(seconds))
}

@Test func runningElapsedSubtractsPastPauses() {
    #expect(elapsed(.inProgress, accumulated: 20, at: 100) == 80)
}

@Test func pausedElapsedFreezesAtPauseInstant() {
    let paused = t0.addingTimeInterval(60)
    #expect(elapsed(.inProgress, paused: paused, at: 60) == 60)
    #expect(elapsed(.inProgress, paused: paused, at: 3600) == 60)
}

@Test func completedElapsedIsStoredDuration() {
    #expect(elapsed(.completed, actual: 95, at: 9999) == 95)
}

@Test func elapsedIsNeverNegative() {
    #expect(elapsed(.inProgress, accumulated: 500, at: 10) == 0)
    #expect(elapsed(.inProgress, at: -30) == 0)
    #expect(elapsed(.completed, actual: -5, at: 0) == 0)
    #expect(elapsed(.draft, started: nil, at: 10) == 0)
}

@Test func elapsedIsRebuiltFromTimestampsAfterBackground() {
    #expect(elapsed(.inProgress, at: 5) == 5)
    #expect(elapsed(.inProgress, at: 905) == 905)
}

@MainActor
private final class Clock {
    var date = t0
    func advance(_ seconds: Double) { date = date.addingTimeInterval(seconds) }
}

@MainActor
private func makeSession(clock: Clock) throws -> (BrewSessionController, Brew, ModelContainer) {
    let schema = Schema([Coffee.self, Brew.self, TasteEvaluation.self, BrewRecommendation.self])
    let container = try ModelContainer(for: schema,
                                       configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    let context = container.mainContext
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    let brew = Brew(coffee: coffee, method: .v60, coffeeGrams: 15, grindDisplayValue: "Medium",
                    createdAt: t0, waterGrams: 250, targetDurationSeconds: 180)
    context.insert(coffee)
    context.insert(brew)
    try context.save()
    return (BrewSessionController(brew: brew, context: context, now: { clock.date }), brew, container)
}

@Test @MainActor func startMovesDraftToRunningOnce() throws {
    let clock = Clock()
    let (session, brew, container) = try makeSession(clock: clock)
    defer { withExtendedLifetime(container) {} }
    session.start()
    #expect(brew.status == .inProgress)
    #expect(brew.startedAt == t0)

    clock.advance(30)
    session.start()
    #expect(brew.startedAt == t0)
}

@Test @MainActor func pauseAndResumeDoNotCountPauseTwice() throws {
    let clock = Clock()
    let (session, brew, container) = try makeSession(clock: clock)
    defer { withExtendedLifetime(container) {} }
    session.start()
    clock.advance(60)
    session.pause()
    clock.advance(10)
    session.pause()
    #expect(brew.pausedAt == t0.addingTimeInterval(60))

    clock.advance(20)
    session.resume()
    session.resume()
    #expect(brew.pausedAt == nil)
    #expect(brew.accumulatedPausedSeconds == 30)
    #expect(brew.elapsedSeconds(at: clock.date) == 60)
}

@Test @MainActor func finishWhilePausedExcludesPausedTime() throws {
    let clock = Clock()
    let (session, brew, container) = try makeSession(clock: clock)
    defer { withExtendedLifetime(container) {} }
    session.start()
    clock.advance(90)
    session.pause()
    clock.advance(600)
    #expect(session.finish())
    #expect(brew.status == .completed)
    #expect(brew.actualDurationSeconds == 90)
    #expect(brew.completedAt == clock.date)
}

@Test @MainActor func finishWhileRunningStoresElapsed() throws {
    let clock = Clock()
    let (session, brew, container) = try makeSession(clock: clock)
    defer { withExtendedLifetime(container) {} }
    session.start()
    clock.advance(45)
    session.pause()
    clock.advance(15)
    session.resume()
    clock.advance(30)
    session.finish()
    #expect(brew.actualDurationSeconds == 75)
}

@Test @MainActor func completedBrewCannotBeResumedOrRestarted() throws {
    let clock = Clock()
    let (session, brew, container) = try makeSession(clock: clock)
    defer { withExtendedLifetime(container) {} }
    session.start()
    clock.advance(60)
    session.finish()
    let completedAt = brew.completedAt

    clock.advance(60)
    session.resume()
    session.pause()
    session.start()
    #expect(!session.finish())
    #expect(brew.status == .completed)
    #expect(brew.pausedAt == nil)
    #expect(brew.completedAt == completedAt)
    #expect(brew.actualDurationSeconds == 60)
}

@Test @MainActor func draftCannotBePausedOrFinished() throws {
    let clock = Clock()
    let (session, brew, container) = try makeSession(clock: clock)
    defer { withExtendedLifetime(container) {} }
    session.pause()
    session.resume()
    #expect(!session.finish())
    #expect(brew.status == .draft)
    #expect(brew.startedAt == nil)
}

@Test @MainActor func setupCreatesPersistedDraftHiddenFromHistoryUntilFinished() throws {
    let schema = Schema([Coffee.self, Brew.self, TasteEvaluation.self, BrewRecommendation.self])
    let container = try ModelContainer(for: schema,
                                       configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
    let context = container.mainContext
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    context.insert(coffee)

    let setup = BrewSetupViewModel(coffee: coffee, method: .v60)
    setup.grindDisplayValue = "Medium"
    setup.durationMinutes = 3
    setup.durationSeconds = 15
    let brew = try #require(setup.saveDraft(in: context))

    #expect(brew.status == .draft)
    #expect(brew.targetDurationSeconds == 195)
    #expect(brew.actualDurationSeconds == nil)
    #expect(try context.fetch(FetchDescriptor<Brew>()).count == 1)
    #expect(coffee.completedBrews.isEmpty)

    let session = BrewSessionController(brew: brew, context: context)
    session.start()
    #expect(coffee.completedBrews.isEmpty)
    session.finish()
    #expect(coffee.completedBrews.count == 1)
}

@Test func brewsWithoutStatusDefaultToCompleted() {
    let brew = Brew(coffee: Coffee(name: "A", origin: "B", roastLevel: .medium), method: .v60,
                    coffeeGrams: 15, grindDisplayValue: "Medium", status: .completed,
                    completedAt: t0, waterGrams: 250)
    brew.statusRawValue = "unknown"
    #expect(brew.status == .completed)
}

@MainActor
private func completedBrew(method: BrewMethod = .v60, water: Double? = 250,
                           beverage: Double? = nil, temperature: Double? = 94) -> Brew {
    Brew(coffee: Coffee(name: "A", origin: "B", roastLevel: .medium), method: method,
         coffeeGrams: 15, grindDisplayValue: "Medium", status: .completed,
         completedAt: t0, waterGrams: water, beverageGrams: beverage,
         temperatureCelsius: temperature)
}

@Test @MainActor func settingsWithoutRecommendationShowEveryStoredValue() {
    let titles = BrewSetting.all(for: completedBrew()).map(\.title)

    #expect(titles == ["Coffee", "Water", "Grind", "Temperature"])
}

@Test @MainActor func espressoSettingsShowBeverageInsteadOfWater() {
    let brew = completedBrew(method: .espresso, water: nil, beverage: 36)
    let titles = BrewSetting.all(for: brew).map(\.title)

    #expect(!titles.contains("Water"))
    #expect(titles.contains("Beverage"))
}

@Test @MainActor func settingsHideTheVariableTheRecommendationChanges() throws {
    let brew = completedBrew()
    let decision = try #require(engine.recommend(for: input(strength: 1, goal: .stronger)))
    let recommendation = BrewRecommendation(brew: brew, decision: decision)
    let titles = BrewSetting.all(for: brew, recommendation: recommendation).map(\.title)

    #expect(decision.variable == .water)
    #expect(!titles.contains("Water"))
    #expect(titles.contains("Grind"))
}

@Test @MainActor func durationFormatsMinutesAndSeconds() {
    #expect(BrewSetting.duration(0) == "0:00")
    #expect(BrewSetting.duration(168) == "2:48")
    #expect(BrewSetting.duration(725) == "12:05")
}

@Test @MainActor func tasteDimensionsReadTheirOwnValue() {
    let evaluation = TasteEvaluation(brew: completedBrew(), acidityValue: 1, bitternessValue: 2,
                                     strengthValue: 4, overallValue: 5)

    #expect(TasteDimension.acidity.value(in: evaluation) == 1)
    #expect(TasteDimension.bitterness.value(in: evaluation) == 2)
    #expect(TasteDimension.strength.value(in: evaluation) == 4)
    #expect(TasteDimension.overall.value(in: evaluation) == 5)
    #expect(TasteDimension.allCases.filter(\.isCumulative) == [.overall])
}
