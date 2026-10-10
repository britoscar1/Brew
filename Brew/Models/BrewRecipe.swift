//
//  BrewRecipe.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 09/10/26.
//

import Foundation

struct GuidedBrewStep: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let instruction: String
    let startsAtSeconds: Double
    let cumulativeWaterGrams: Double?

    func scaled(time: Double, water: Double) -> Self {
        Self(id: id, title: title, instruction: instruction,
             startsAtSeconds: startsAtSeconds * time,
             cumulativeWaterGrams: cumulativeWaterGrams.map { $0 * water })
    }
}

struct BrewRecipe: Identifiable {
    let id: String
    let method: BrewMethod
    let name: String
    let grind: String
    let durationSeconds: Double
    let steps: [GuidedBrewStep]

    var coffeeGrams: Double { method.defaults.coffeeGrams }
    var waterGrams: Double? { method.defaults.waterGrams }
    var beverageGrams: Double? { method.defaults.beverageGrams }
    var temperatureCelsius: Double { method.defaults.temperatureCelsius }

    static func starter(for method: BrewMethod) -> BrewRecipe {
        switch method {
        case .v60:
            BrewRecipe(id: "v60-starter-v1", method: method, name: String(localized: "V60 starter"),
                       grind: String(localized: "Medium-fine"), durationSeconds: 180, steps: [
                step(0, "Bloom", "Wet all the grounds and let the coffee bloom.", at: 0, water: 50),
                step(1, "First pour", "Pour slowly in circles to the cumulative water target.", at: 30, water: 150),
                step(2, "Final pour", "Add the remaining water gently.", at: 60, water: 250),
                step(3, "Draw down", "Let the water drain. Finish when the dripping slows.", at: 90)
            ])
        case .aeroPress:
            BrewRecipe(id: "aeropress-starter-v1", method: method, name: String(localized: "AeroPress starter"),
                       grind: String(localized: "Medium-fine"), durationSeconds: 150, steps: [
                step(0, "Add water", "Use the upright position with a rinsed paper filter. Add coffee and water.", at: 0, water: 240),
                step(1, "Stir and steep", "Stir gently, then insert the plunger slightly to limit dripping.", at: 15),
                step(2, "Press", "Press gently and steadily. Stop when you hear the hiss.", at: 120)
            ])
        case .frenchPress:
            BrewRecipe(id: "french-press-starter-v1", method: method, name: String(localized: "French Press starter"),
                       grind: String(localized: "Coarse"), durationSeconds: 240, steps: [
                step(0, "Add water", "Add coffee and water, wetting all the grounds.", at: 0, water: 500),
                step(1, "Steep", "Stir gently and place the lid on without pressing.", at: 30),
                step(2, "Press and serve", "Lower the plunger gently and pour the coffee into your cup.", at: 240)
            ])
        case .espresso:
            BrewRecipe(id: "espresso-starter-v1", method: method, name: String(localized: "Espresso starter"),
                       grind: String(localized: "Fine"), durationSeconds: 30, steps: [
                step(0, "Extract", "Distribute and tamp before starting. Start the timer with the pump.", at: 0),
                step(1, "Check yield", "Stop the pump at your beverage target. Time is a guide; finish when the shot is done.", at: 25)
            ])
        }
    }

    private static func step(_ id: Int, _ title: String.LocalizationValue,
                             _ instruction: String.LocalizationValue, at seconds: Double,
                             water: Double? = nil) -> GuidedBrewStep {
        GuidedBrewStep(id: id, title: String(localized: title), instruction: String(localized: instruction),
                       startsAtSeconds: seconds, cumulativeWaterGrams: water)
    }
}

struct BrewGuide {
    let steps: [GuidedBrewStep]

    func currentIndex(at elapsed: Double) -> Int? {
        steps.lastIndex { $0.startsAtSeconds <= elapsed }
    }

    func current(at elapsed: Double) -> GuidedBrewStep? {
        currentIndex(at: elapsed).map { steps[$0] }
    }

    func next(at elapsed: Double) -> GuidedBrewStep? {
        guard let index = currentIndex(at: elapsed) else { return steps.first }
        return steps.indices.contains(index + 1) ? steps[index + 1] : nil
    }
}
