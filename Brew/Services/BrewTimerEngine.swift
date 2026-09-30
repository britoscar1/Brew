//
//  BrewTimerEngine.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 29/09/26.
//

import Foundation

struct BrewTimerEngine {
    func elapsedSeconds(status: BrewStatus, startedAt: Date?, pausedAt: Date?,
                        accumulatedPausedSeconds: Double, actualDurationSeconds: Double?,
                        now: Date) -> Double {
        switch status {
        case .draft:
            return 0
        case .completed:
            return max(0, actualDurationSeconds ?? 0)
        case .inProgress:
            guard let startedAt else { return 0 }
            let end = pausedAt ?? now
            return max(0, end.timeIntervalSince(startedAt) - accumulatedPausedSeconds)
        }
    }
}

extension Brew {
    func elapsedSeconds(at now: Date) -> Double {
        BrewTimerEngine().elapsedSeconds(
            status: status, startedAt: startedAt, pausedAt: pausedAt,
            accumulatedPausedSeconds: accumulatedPausedSeconds,
            actualDurationSeconds: actualDurationSeconds, now: now
        )
    }
}
