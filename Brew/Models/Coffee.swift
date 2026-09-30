//
//  Coffee.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import Foundation
import SwiftData

@Model
class Coffee {
    var name: String
    var origin: String
    var roastLevelRawValue: String
    var roaster: String?
    var process: String?
    var notes: String?
    var roastDate: Date?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Brew.coffee)
    var brews: [Brew] = []

    var completedBrews: [Brew] {
        brews.filter { $0.status == .completed }.sorted { $0.sortDate > $1.sortDate }
    }

    var roastLevel: RoastLevel? {
        RoastLevel(rawValue: roastLevelRawValue)
    }

    init(name: String, origin: String, roastLevel: RoastLevel,
         roaster: String? = nil, process: String? = nil,
         notes: String? = nil, roastDate: Date? = nil) {
        self.name = name
        self.origin = origin
        roastLevelRawValue = roastLevel.rawValue
        self.roaster = roaster
        self.process = process
        self.notes = notes
        self.roastDate = roastDate
        let now = Date()
        createdAt = now
        updatedAt = now
    }
}

extension Coffee {
    func archive() {
        archivedAt = .now
        updatedAt = .now
    }

    func restore() {
        archivedAt = nil
        updatedAt = .now
    }
}
