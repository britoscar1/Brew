//
//  InterruptedBrews.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 08/10/26.
//

import Foundation
import SwiftData

@MainActor
enum InterruptedBrews {
    static func pending(in brews: [Brew]) -> [Brew] {
        brews
            .filter { $0.status != .completed }
            .sorted { $0.createdAt > $1.createdAt }
    }

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
