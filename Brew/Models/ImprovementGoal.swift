//
//  ImprovementGoal.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import Foundation

enum ImprovementGoal: String, CaseIterable, Identifiable {
    case lessAcidic, lessBitter, stronger, weaker, keepAsIs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lessAcidic: String(localized: "Less acidic")
        case .lessBitter: String(localized: "Less bitter")
        case .stronger: String(localized: "Stronger")
        case .weaker: String(localized: "Weaker")
        case .keepAsIs: String(localized: "Keep as is")
        }
    }
}
