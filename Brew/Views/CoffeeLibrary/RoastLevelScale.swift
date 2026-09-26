//
//  RoastLevelScale.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import SwiftUI

struct RoastLevelScale: View {
    let level: RoastLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(RoastLevel.allCases) { step in
                    Capsule()
                        .fill(Color("CoffeeTint").opacity(step == level ? darkness(step) : 0.15))
                        .frame(height: step == level ? 10 : 6)
                }
            }
            .frame(height: 10)

            HStack {
                Text("Light")
                Spacer()
                Text("Dark")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement()
        .accessibilityLabel("Roast level")
        .accessibilityValue(level.title)
    }

    private func darkness(_ level: RoastLevel) -> Double {
        switch level {
        case .light: 0.35
        case .mediumLight: 0.5
        case .medium: 0.65
        case .mediumDark: 0.8
        case .dark: 1
        }
    }
}
