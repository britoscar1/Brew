//
//  PersistenceAction.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 09/10/26.
//

import SwiftData
import SwiftUI

@MainActor
enum PersistenceAction {
    @discardableResult
    static func save(in context: ModelContext,
                     persist: (ModelContext) throws -> Void = { try $0.save() },
                     restore: () -> Void,
                     mutation: () -> Void) -> Bool {
        mutation()
        context.processPendingChanges()
        do {
            try persist(context)
            return true
        } catch {
            context.rollback()
            restore()
            return false
        }
    }
}

extension View {
    func persistenceErrorAlert(isPresented: Binding<Bool>) -> some View {
        alert("Couldn't save changes", isPresented: isPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your changes couldn't be saved. Please try again.")
        }
    }
}

@MainActor
extension Coffee {
    @discardableResult
    func archive(in context: ModelContext) -> Bool {
        saveArchiveState(archived: true, in: context)
    }

    @discardableResult
    func restore(in context: ModelContext) -> Bool {
        saveArchiveState(archived: false, in: context)
    }

    private func saveArchiveState(archived: Bool, in context: ModelContext) -> Bool {
        let snapshot = (archivedAt, updatedAt)
        return PersistenceAction.save(in: context, restore: {
            (self.archivedAt, self.updatedAt) = snapshot
        }) {
            if archived { self.archive() } else { self.restore() }
        }
    }
}
