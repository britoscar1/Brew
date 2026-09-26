//
//  ContentView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Brew", systemImage: "timer") {
                BrewView()
            }

            Tab("Library", image: "CoffeeBeansOutline") {
                CoffeeLibraryView()
            }
        }
        .tint(Color("CoffeeTint"))
    }
}

#Preview {
    ContentView().modelContainer(for: Coffee.self, inMemory: true)
}
