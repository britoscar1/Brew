//
//  BrewSessionController.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 29/09/26.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class BrewSessionController {
    private let brew: Brew
    private let context: ModelContext
    private let now: () -> Date

    var saveFailed = false

    init(brew: Brew, context: ModelContext, now: @escaping () -> Date = { .now }) {
        self.brew = brew
        self.context = context
        self.now = now
    }

    var isPaused: Bool {
        brew.status == .inProgress && brew.pausedAt != nil
    }

    func start() {
        guard brew.status == .draft else { return }
        let date = now()
        commit {
            brew.status = .inProgress
            brew.startedAt = date
            brew.pausedAt = nil
            brew.accumulatedPausedSeconds = 0
        }
    }

    func pause() {
        guard brew.status == .inProgress, brew.pausedAt == nil else { return }
        let date = now()
        commit { brew.pausedAt = date }
    }

    func resume() {
        guard brew.status == .inProgress, let pausedAt = brew.pausedAt else { return }
        let date = now()
        commit {
            brew.accumulatedPausedSeconds += max(0, date.timeIntervalSince(pausedAt))
            brew.pausedAt = nil
        }
    }

    @discardableResult
    func finish() -> Bool {
        guard brew.status == .inProgress else { return false }
        let date = now()
        return commit {
            if let pausedAt = brew.pausedAt {
                brew.accumulatedPausedSeconds += max(0, date.timeIntervalSince(pausedAt))
                brew.pausedAt = nil
            }
            brew.actualDurationSeconds = brew.elapsedSeconds(at: date)
            brew.completedAt = date
            brew.status = .completed
        }
    }

    @discardableResult
    private func commit(_ mutation: () -> Void) -> Bool {
        let snapshot = (brew.statusRawValue, brew.startedAt, brew.pausedAt,
                        brew.accumulatedPausedSeconds, brew.actualDurationSeconds, brew.completedAt)
        mutation()

        do {
            try context.save()
            return true
        } catch {
            (brew.statusRawValue, brew.startedAt, brew.pausedAt,
             brew.accumulatedPausedSeconds, brew.actualDurationSeconds, brew.completedAt) = snapshot
            saveFailed = true
            return false
        }
    }
}
