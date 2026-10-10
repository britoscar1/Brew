//
//  TopBrewsManager.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 08/10/26.
//

import Foundation
import SwiftData

@MainActor
struct TopBrewsManager {
    static let positions = [1, 2, 3]

    let coffee: Coffee

    var ranked: [Brew] {
        coffee.brews
            .filter { $0.topBrewRank != nil }
            .sorted { ($0.topBrewRank ?? 0) < ($1.topBrewRank ?? 0) }
    }

    func brew(at position: Int) -> Brew? {
        coffee.brews.first { $0.topBrewRank == position }
    }

    func canHoldAPosition(_ brew: Brew) -> Bool {
        brew.status == .completed && brew.coffee === coffee
    }

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

    @discardableResult
    func remove(_ brew: Brew, in context: ModelContext) -> Bool {
        guard brew.coffee === coffee else { return false }
        let rank = brew.topBrewRank
        return PersistenceAction.save(in: context, restore: { brew.topBrewRank = rank }) {
            brew.topBrewRank = nil
        }
    }
}
