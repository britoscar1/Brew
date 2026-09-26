//
//  BrewApp.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import SwiftUI
import SwiftData

@main
struct BrewApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Coffee.self,
            Brew.self,
            TasteEvaluation.self,
            BrewRecommendation.self,
        ])
        let modelConfiguration = ModelConfiguration("CoffeeLibrary", schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
