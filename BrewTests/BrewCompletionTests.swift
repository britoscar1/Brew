//
//  BrewCompletionTests.swift
//  BrewTests
//
//  Created by Oscar Artemio Brito Ortiz on 09/10/26.
//

import Testing
import Foundation
import SwiftData
@testable import Brew

@MainActor
private func testContainer(url: URL? = nil) throws -> ModelContainer {
    let schema = Schema([Coffee.self, Brew.self, TasteEvaluation.self, BrewRecommendation.self])
    let configuration = url.map { ModelConfiguration(schema: schema, url: $0, cloudKitDatabase: .none) }
        ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
}

@Test @MainActor func everyMethodHasACompleteStarterRecipe() throws {
    let container = try testContainer()
    let coffee = Coffee(name: "Recipe test", origin: "Test", roastLevel: .medium)
    container.mainContext.insert(coffee)
    for method in BrewMethod.allCases {
        let setup = BrewSetupViewModel(coffee: coffee, method: method)
        let recipe = setup.starterRecipe
        setup.selectRecipe(recipe.id)
        #expect(setup.canSave)
        let brew = try #require(setup.saveDraft(in: container.mainContext))
        #expect(brew.recipeName == recipe.name)
        #expect(brew.guidedSteps == recipe.steps)
        #expect(brew.guidedSteps.first?.startsAtSeconds == 0)
        #expect(zip(brew.guidedSteps, brew.guidedSteps.dropFirst()).allSatisfy {
            $0.startsAtSeconds < $1.startsAtSeconds
        })
        #expect(brew.targetDurationSeconds == recipe.durationSeconds)
    }
}

@Test @MainActor func editedSetupScalesAndFreezesStepTargets() throws {
    let container = try testContainer()
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    container.mainContext.insert(coffee)
    let setup = BrewSetupViewModel(coffee: coffee, method: .v60)
    setup.selectRecipe(setup.starterRecipe.id)
    setup.waterGrams = 500
    setup.durationMinutes = 6
    let brew = try #require(setup.saveDraft(in: container.mainContext))
    #expect(brew.guidedSteps[1].startsAtSeconds == 60)
    #expect(brew.guidedSteps[1].cumulativeWaterGrams == 300)
    #expect(brew.guidedSteps[2].cumulativeWaterGrams == 500)
    setup.waterGrams = 1000
    setup.selectRecipe(nil)
    #expect(setup.guidedSteps.isEmpty)
    #expect(brew.guidedSteps[2].cumulativeWaterGrams == 500)
    #expect(BrewRecipe.starter(for: .v60).steps[2].cumulativeWaterGrams == 250)
}

@Test func guideTransitionsAtEachBoundaryAndKeepsTheFinalInstruction() {
    let steps = BrewRecipe.starter(for: .v60).steps
    let guide = BrewGuide(steps: steps)
    #expect(guide.current(at: 0)?.title == steps[0].title)
    #expect(guide.current(at: 29.9)?.id == 0)
    #expect(guide.current(at: 30)?.id == 1)
    #expect(guide.next(at: 30)?.id == 2)
    #expect(guide.current(at: 1000)?.id == 3)
    #expect(guide.next(at: 1000) == nil)
    #expect(BrewGuide(steps: []).current(at: 0) == nil)
}

@Test @MainActor func repeatPreservesStepsAndScalesAnAppliedWaterAdjustment() throws {
    let container = try testContainer()
    let context = container.mainContext
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    context.insert(coffee)
    let setup = BrewSetupViewModel(coffee: coffee, method: .v60)
    setup.selectRecipe(setup.starterRecipe.id)
    let original = try #require(setup.saveDraft(in: context))
    original.status = .completed
    let evaluation = TasteEvaluationViewModel(brew: original)
    evaluation.strengthValue = 1
    evaluation.improvementGoal = .stronger
    #expect(evaluation.save(in: context))
    let repeated = try #require(BrewSetupViewModel(repeating: original))
    let copy = try #require(repeated.saveDraft(in: context))
    #expect(copy.guidedSteps == original.guidedSteps)
    #expect(copy.recipeName == original.recipeName)
    let adjustment = try #require(BrewAdjustment(brew: original))
    let adjusted = try #require(BrewSetupViewModel(repeating: original, adjustment: adjustment))
    let adjustedCopy = try #require(adjusted.saveDraft(in: context))
    #expect(adjustedCopy.guidedSteps[2].cumulativeWaterGrams == adjustedCopy.waterGrams)
    #expect(adjustedCopy.guidedSteps.map(\.startsAtSeconds) == original.guidedSteps.map(\.startsAtSeconds))
    #expect(original.waterGrams == 250)
}

@Test @MainActor func invalidAmountsTemperatureAndTimeCannotBeSaved() throws {
    let container = try testContainer()
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    container.mainContext.insert(coffee)
    let setup = BrewSetupViewModel(coffee: coffee, method: .espresso)
    setup.grindDisplayValue = "Fine"
    for invalid in [0.0, -1, .infinity, .nan, 501] {
        setup.coffeeGrams = invalid
        #expect(!setup.canSave)
    }
    setup.coffeeGrams = 18
    for invalid in [0.0, -1, 101, .nan, .infinity] {
        setup.temperatureCelsius = invalid
        #expect(!setup.canSave)
    }
    setup.temperatureCelsius = nil
    #expect(setup.canSave)
    for (minutes, seconds) in [(0, 0), (-1, 30), (0, -1), (0, 60), (121, 0), (Int.max, 0)] {
        setup.durationMinutes = minutes
        setup.durationSeconds = seconds
        #expect(!setup.canSave)
        _ = setup.guidedSteps
        #expect(setup.saveDraft(in: container.mainContext) == nil)
    }
    setup.durationMinutes = 0
    setup.durationSeconds = 30
    #expect(setup.canSave)
    coffee.archive()
    #expect(!setup.canSave)
}

@Test func smallRecommendationsActuallyChangeInTheRequestedDirection() throws {
    let engine = RecommendationEngine()
    for method in BrewMethod.allCases {
        for amount in [1.0, 5, 8, 10, 36, 250] {
            for goal in [ImprovementGoal.stronger, .weaker] {
                let input = RecommendationInput(acidity: 3, bitterness: 3,
                                                strength: goal == .stronger ? 1 : 5,
                                                overall: 2, goal: goal, method: method,
                                                waterGrams: amount, beverageGrams: amount, grindDisplayValue: "Fine")
                let decision = try #require(engine.recommend(for: input))
                if case let .grams(target) = decision.suggestedValue {
                    #expect(target > 0)
                    #expect(goal == .stronger ? target < amount : target > amount)
                } else {
                    #expect(decision.direction == .unclear)
                }
            }
        }
    }
}

@Test @MainActor func failedPersistenceRollsBackAndReportsFailure() throws {
    enum TestError: Error { case saveFailed }
    let container = try testContainer()
    let context = container.mainContext
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    context.insert(coffee)
    try context.save()
    let updatedAt = coffee.updatedAt
    let succeeded = PersistenceAction.save(in: context, persist: { _ in throw TestError.saveFailed }, restore: {
        coffee.archivedAt = nil
        coffee.updatedAt = updatedAt
    }) { coffee.archive() }
    #expect(!succeeded)
    #expect(coffee.archivedAt == nil)
    #expect(coffee.updatedAt == updatedAt)
    try context.save()
    #expect(try context.fetch(FetchDescriptor<Coffee>()).first?.archivedAt == nil)
}

@Test @MainActor func notesAndGuidedStepsSurviveReopeningTheDiskStore() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("test.store")
    try autoreleasepool {
        let container = try testContainer(url: url)
        let context = container.mainContext
        let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
        context.insert(coffee)
        let setup = BrewSetupViewModel(coffee: coffee, method: .aeroPress)
        setup.selectRecipe(setup.starterRecipe.id)
        let brew = try #require(setup.saveDraft(in: context))
        let session = BrewSessionController(brew: brew, context: context)
        session.start()
        #expect(session.finish())
        let evaluation = TasteEvaluationViewModel(brew: brew)
        evaluation.notes = "  Peach and chocolate  "
        #expect(evaluation.save(in: context))
    }
    let reopened = try testContainer(url: url)
    let brew = try #require(reopened.mainContext.fetch(FetchDescriptor<Brew>()).first)
    #expect(brew.status == .completed)
    #expect(brew.tasteEvaluation?.notes == "Peach and chocolate")
    #expect(brew.guidedSteps == BrewRecipe.starter(for: .aeroPress).steps)
    let evaluation = TasteEvaluationViewModel(brew: brew)
    #expect(evaluation.notes == "Peach and chocolate")
    evaluation.notes = "   "
    #expect(evaluation.save(in: reopened.mainContext))
    #expect(brew.tasteEvaluation?.notes == nil)
}

@Test @MainActor func aCompletedBrewWithoutEvaluationCanBeEvaluatedLater() throws {
    let container = try testContainer()
    let context = container.mainContext
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    context.insert(coffee)
    let setup = BrewSetupViewModel(coffee: coffee, method: .frenchPress)
    setup.selectRecipe(setup.starterRecipe.id)
    let brew = try #require(setup.saveDraft(in: context))
    let session = BrewSessionController(brew: brew, context: context)
    session.start()
    #expect(session.finish())
    #expect(coffee.completedBrews.count == 1)
    #expect(brew.tasteEvaluation == nil)
    #expect(brew.recommendation == nil)
    let evaluation = TasteEvaluationViewModel(brew: brew)
    evaluation.notes = "Added later"
    #expect(evaluation.save(in: context))
    #expect(brew.tasteEvaluation?.notes == "Added later")
    #expect(brew.recommendation != nil)
}

@Test @MainActor func corruptLegacyTimesDoNotCrashFormatting() {
    for value in [Double.nan, .infinity, -.infinity, -1, Double(Int.max)] {
        #expect(BrewSetting.duration(value) == "—")
    }
}

@Test @MainActor func guideFollowsElapsedTimeAcrossPauseAndResume() throws {
    let container = try testContainer()
    let context = container.mainContext
    let coffee = Coffee(name: "Test", origin: "Test", roastLevel: .medium)
    context.insert(coffee)
    let setup = BrewSetupViewModel(coffee: coffee, method: .v60)
    setup.selectRecipe(setup.starterRecipe.id)
    let brew = try #require(setup.saveDraft(in: context))
    var now = Date(timeIntervalSinceReferenceDate: 1000)
    let session = BrewSessionController(brew: brew, context: context, now: { now })
    let guide = BrewGuide(steps: brew.guidedSteps)
    session.start()
    now = now.addingTimeInterval(20)
    session.pause()
    now = now.addingTimeInterval(300)
    #expect(guide.current(at: brew.elapsedSeconds(at: now))?.id == 0)
    session.resume()
    now = now.addingTimeInterval(10)
    #expect(guide.current(at: brew.elapsedSeconds(at: now))?.id == 1)
    #expect(guide.next(at: brew.elapsedSeconds(at: now))?.id == 2)
}
