//
//  RoastLevel.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import Foundation

enum RoastLevel: String, CaseIterable, Identifiable {
    case light, mediumLight, medium, mediumDark, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .light: String(localized: "Light")
        case .mediumLight: String(localized: "Medium Light")
        case .medium: String(localized: "Medium")
        case .mediumDark: String(localized: "Medium Dark")
        case .dark: String(localized: "Dark")
        }
    }
}
