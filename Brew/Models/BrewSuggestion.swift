//
//  BrewSuggestion.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 03/10/26.
//

import Foundation

struct BrewSuggestion {
    enum Kind {
        /// Change the one variable the engine named.
        case adjust(BrewAdjustment)
        /// The brew was enjoyed: reproduce it exactly.
        case keep
        /// No clear conclusion: the engine asks for one more identical attempt.
        case tryAgain
    }

    let source: Brew
    let kind: Kind

    var adjustment: BrewAdjustment? {
        guard case let .adjust(adjustment) = kind else { return nil }
        return adjustment
    }

    var title: String {
        switch kind {
        case let .adjust(adjustment):
            String(localized: "\(adjustment.title) than \(adjustment.previousDisplayValue)")
        case .keep:
            String(localized: "Keep the settings you liked")
        case .tryAgain:
            String(localized: "Try the same brew again")
        }
    }

    /// The most recent completed brew of this coffee and method that was evaluated.
    /// Every recommendation leads somewhere, including the ones that ask for no
    /// change — offering an older adjustment over them would contradict the advice
    /// the person just read. `completedBrews` is already newest first.
    init?(lastOf coffee: Coffee, method: BrewMethod) {
        guard let brew = coffee.completedBrews.first(where: {
            $0.method == method && $0.recommendation != nil
        }) else { return nil }

        switch brew.recommendation?.direction {
        case .maintain:
            kind = .keep
        case .unclear:
            kind = .tryAgain
        case .finer, .coarser, .increase, .decrease:
            guard let adjustment = BrewAdjustment(brew: brew) else { return nil }
            kind = .adjust(adjustment)
        case nil:
            return nil
        }

        source = brew
    }
}
