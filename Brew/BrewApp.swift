//
//  BrewApp.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class BrewStore {
    private(set) var container: ModelContainer?

    init() { open() }

    func open() {
        let schema = Schema([Coffee.self, Brew.self, TasteEvaluation.self, BrewRecommendation.self])
        let configuration: ModelConfiguration
        #if DEBUG
        if let testID = ProcessInfo.processInfo.environment["BREW_UI_TEST_STORE"],
           let id = UUID(uuidString: testID) {
            let url = URL.applicationSupportDirectory.appendingPathComponent("ui-test-\(id.uuidString).store")
            configuration = ModelConfiguration("UITests", schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration("CoffeeLibrary", schema: schema, cloudKitDatabase: .none)
        }
        #else
        configuration = ModelConfiguration("CoffeeLibrary", schema: schema, cloudKitDatabase: .none)
        #endif

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            container = nil
        }
    }
}

@main
struct BrewApp: App {
    @State private var store = BrewStore()

    var body: some Scene {
        WindowGroup {
            if let container = store.container {
                ContentView().modelContainer(container)
            } else {
                ContentUnavailableView {
                    Label("Couldn't open your library", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your saved data has not been deleted. Try opening your library again.")
                } actions: {
                    Button("Try again") { store.open() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
