//
//  BrewSetupViewModel.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 17/09/26.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class BrewSetupViewModel {
    let coffee: Coffee
    let method: BrewMethod

    /// The adjustment currently seeded into these values, if any.
    private(set) var adjustment: BrewAdjustment?

    /// The most recent brew of this coffee and method whose recommendation can
    /// still be acted on. Offered at the top of Brew Setup, never applied on its own.
    let suggestion: BrewSuggestion?

    /// True once the person took the suggestion. Not the same as having an
    /// adjustment: keeping the settings you liked changes nothing to flag.
    private(set) var hasAppliedSuggestion = false

    var coffeeGrams: Double?
    var waterGrams: Double?
    var beverageGrams: Double?
    var temperatureCelsius: Double?
    var grindDisplayValue = ""
    var durationMinutes: Int?
    var durationSeconds: Int?

    init(coffee: Coffee, method: BrewMethod) {
        self.coffee = coffee
        self.method = method
        adjustment = nil
        suggestion = BrewSuggestion(lastOf: coffee, method: method)

        let defaults = method.defaults
        coffeeGrams = defaults.coffeeGrams
        waterGrams = defaults.waterGrams
        beverageGrams = defaults.beverageGrams
        temperatureCelsius = defaults.temperatureCelsius
    }

    /// Replaces the method defaults with the suggested brew's values. Only the
    /// person tapping Apply calls this; entering Brew Setup never does.
    func applySuggestion() {
        guard let suggestion else { return }

        adjustment = suggestion.adjustment
        hasAppliedSuggestion = true
        seed(from: suggestion.source, adjustment: suggestion.adjustment)
    }

    /// Fails for an archived coffee: it is out of the active library, so it cannot
    /// start a new brew from its history either (COF-04).
    init?(repeating source: Brew, adjustment: BrewAdjustment? = nil) {
        guard let coffee = source.coffee, coffee.archivedAt == nil,
              let method = source.method else { return nil }

        self.coffee = coffee
        self.method = method
        self.adjustment = adjustment
        suggestion = nil

        seed(from: source, adjustment: adjustment)
    }

    private func seed(from source: Brew, adjustment: BrewAdjustment?) {
        coffeeGrams = source.coffeeGrams
        waterGrams = source.waterGrams
        beverageGrams = source.beverageGrams
        temperatureCelsius = source.temperatureCelsius
        grindDisplayValue = source.grindDisplayValue
        durationMinutes = nil
        durationSeconds = nil

        if let target = source.targetDurationSeconds, target > 0 {
            let total = Int(target)
            durationMinutes = total / 60
            durationSeconds = total % 60
        }

        guard let adjustment else { return }

        switch adjustment.variable {
        case .grind: grindDisplayValue = ""
        case .water: waterGrams = adjustment.suggestedGrams
        case .beverageYield: beverageGrams = adjustment.suggestedGrams
        case .none: break
        }
    }

    var usesBeverageYield: Bool {
        method == .espresso
    }

    var ratio: Double? {
        let yield = usesBeverageYield ? beverageGrams : waterGrams
        guard let yield, let dose = coffeeGrams, dose > 0 else { return nil }
        return yield / dose
    }

    var canSave: Bool {
        guard let coffeeGrams, coffeeGrams > 0,
              !grindDisplayValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        switch method {
        case .v60, .aeroPress, .frenchPress:
            return (waterGrams ?? 0) > 0 && (temperatureCelsius ?? 0) > 0
        case .espresso:
            return (beverageGrams ?? 0) > 0
        }
    }

    func saveDraft(in context: ModelContext) -> Brew? {
        guard canSave, let coffeeGrams else { return nil }

        let brew = Brew(
            coffee: coffee,
            method: method,
            coffeeGrams: coffeeGrams,
            grindDisplayValue: grindDisplayValue.trimmingCharacters(in: .whitespacesAndNewlines),
            waterGrams: usesBeverageYield ? nil : waterGrams,
            beverageGrams: usesBeverageYield ? beverageGrams : nil,
            temperatureCelsius: temperatureCelsius,
            targetDurationSeconds: targetDurationSeconds
        )
        context.insert(brew)

        do {
            try context.save()
            return brew
        } catch {
            context.delete(brew)
            return nil
        }
    }

    private var targetDurationSeconds: Double? {
        guard durationMinutes != nil || durationSeconds != nil else { return nil }
        return Double((durationMinutes ?? 0) * 60 + (durationSeconds ?? 0))
    }
}
