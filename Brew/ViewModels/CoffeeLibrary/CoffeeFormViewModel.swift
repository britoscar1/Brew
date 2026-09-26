//
//  CoffeeFormViewModel.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class CoffeeFormViewModel {
    private let coffee: Coffee?

    var name = ""
    var origin = ""
    var roastLevel: RoastLevel?
    var roaster = ""
    var process = ""
    var notes = ""
    var includesRoastDate = false
    var roastDate = Date()

    init(coffee: Coffee? = nil) {
        self.coffee = coffee

        guard let coffee else { return }

        name = coffee.name
        origin = coffee.origin
        roastLevel = coffee.roastLevel
        roaster = coffee.roaster ?? ""
        process = coffee.process ?? ""
        notes = coffee.notes ?? ""
        includesRoastDate = coffee.roastDate != nil
        roastDate = coffee.roastDate ?? .now
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        roastLevel != nil
    }

    func save(in context: ModelContext) -> Bool {
        guard canSave, let roastLevel else { return false }

        var insertedCoffee: Coffee?

        if let coffee {
            coffee.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            coffee.origin = origin.trimmingCharacters(in: .whitespacesAndNewlines)
            coffee.roastLevelRawValue = roastLevel.rawValue
            coffee.roaster = optionalText(roaster)
            coffee.process = optionalText(process)
            coffee.notes = optionalText(notes)
            coffee.roastDate = includesRoastDate ? roastDate : nil
            coffee.updatedAt = .now
        } else {
            let newCoffee = Coffee(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                origin: origin.trimmingCharacters(in: .whitespacesAndNewlines),
                roastLevel: roastLevel,
                roaster: optionalText(roaster),
                process: optionalText(process),
                notes: optionalText(notes),
                roastDate: includesRoastDate ? roastDate : nil
            )
            context.insert(newCoffee)
            insertedCoffee = newCoffee
        }

        do {
            try context.save()
            return true
        } catch {
            if let insertedCoffee {
                context.delete(insertedCoffee)
            } else {
                context.rollback()
            }
            return false
        }
    }

    private func optionalText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
