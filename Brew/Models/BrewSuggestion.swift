//
//  BrewSuggestion.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 03/10/26.
//

import Foundation

struct BrewSuggestion {
    let source: Brew
    let adjustment: BrewAdjustment

    /// The most recent completed brew of this coffee and method that still has an
    /// adjustment worth applying. `completedBrews` is already newest first.
    init?(lastOf coffee: Coffee, method: BrewMethod) {
        let match = coffee.completedBrews
            .lazy
            .filter { $0.method == method }
            .compactMap { brew in BrewAdjustment(brew: brew).map { (brew, $0) } }
            .first

        guard let match else { return nil }

        source = match.0
        adjustment = match.1
    }
}
