//
//  TopBrewsManager.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 08/10/26.
//

import Foundation
import SwiftData

/// Owns the Top 3 invariants of one coffee. SwiftData cannot express the
/// composite uniqueness of (coffee, topBrewRank), so every assignment goes
/// through here and nothing else writes `topBrewRank`.
@MainActor
struct TopBrewsManager {
    static let positions = [1, 2, 3]

    let coffee: Coffee

    /// The coffee's top brews, position 1 first. Empty positions are left out.
    var ranked: [Brew] {
        coffee.brews
            .filter { $0.topBrewRank != nil }
            .sorted { ($0.topBrewRank ?? 0) < ($1.topBrewRank ?? 0) }
    }

    func brew(at position: Int) -> Brew? {
        coffee.brews.first { $0.topBrewRank == position }
    }

    /// A brew can hold a position only if it is completed and belongs to this
    /// coffee. An unevaluated brew qualifies: taste is not a requirement (TOP-01).
    func canHoldAPosition(_ brew: Brew) -> Bool {
        brew.status == .completed && brew.coffee === coffee
    }

    /// Moves `brew` into `position`, displacing whoever was there. The caller
    /// confirms that replacement first — this type does not ask.
    @discardableResult
    func assign(_ brew: Brew, to position: Int, in context: ModelContext) -> Bool {
        guard Self.positions.contains(position), canHoldAPosition(brew) else { return false }
        let snapshot = coffee.brews.map { ($0, $0.topBrewRank) }
        return PersistenceAction.save(in: context, restore: {
            for (brew, rank) in snapshot { brew.topBrewRank = rank }
        }) {
            self.brew(at: position)?.topBrewRank = nil
            brew.topBrewRank = position
        }
    }

    /// Leaves the brew in the history, out of the Top 3.
    @discardableResult
    func remove(_ brew: Brew, in context: ModelContext) -> Bool {
        guard brew.coffee === coffee else { return false }
        let rank = brew.topBrewRank
        return PersistenceAction.save(in: context, restore: { brew.topBrewRank = rank }) {
            brew.topBrewRank = nil
        }
    }
}
