//
//  TasteDimension.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 01/10/26.
//

import SwiftUI

enum TasteDimension: CaseIterable {
    case acidity, bitterness, strength, overall

    var title: LocalizedStringKey {
        switch self {
        case .acidity: "Acidity"
        case .bitterness: "Bitterness"
        case .strength: "Strength"
        case .overall: "How much you liked it"
        }
    }

    var labels: [LocalizedStringKey] {
        switch self {
        case .acidity: ["Flat", "Low", "Balanced", "Bright", "Sharp"]
        case .bitterness: ["None", "Low", "Balanced", "Bitter", "Harsh"]
        case .strength: ["Watery", "Weak", "Balanced", "Strong", "Intense"]
        case .overall: ["Disliked", "Poor", "Okay", "Good", "Loved"]
        }
    }

    var isCumulative: Bool {
        self == .overall
    }

    func value(in evaluation: TasteEvaluation) -> Int {
        switch self {
        case .acidity: evaluation.acidityValue
        case .bitterness: evaluation.bitternessValue
        case .strength: evaluation.strengthValue
        case .overall: evaluation.overallValue
        }
    }
}
