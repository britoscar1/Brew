//
//  InterruptedBrews.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 08/10/26.
//

import Foundation
import SwiftData

/// A brew that was set up or started but never finished. It stays out of the
/// history and out of the Top 3 until it is completed, so without this it would
/// be invisible and unreachable forever (TMR-03).
@MainActor
enum InterruptedBrews {
    /// Newest first, so the one the person just walked away from comes up.
    static func pending(in brews: [Brew]) -> [Brew] {
        brews
            .filter { $0.status != .completed }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Removes the brew for good. Discarding is the only deletion the MVP has,
    /// and it reaches nothing but an unfinished brew.
    @discardableResult
    static func discard(_ brew: Brew, in context: ModelContext) -> Bool {
        guard brew.status != .completed else { return false }
        let coffee = brew.coffee
        let siblings = coffee?.brews
        return PersistenceAction.save(in: context, restore: {
            brew.coffee = coffee
            if let coffee, let siblings { coffee.brews = siblings }
        }) { context.delete(brew) }
    }
}
