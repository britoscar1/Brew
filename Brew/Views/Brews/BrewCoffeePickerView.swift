//
//  BrewCoffeePickerView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 19/09/26.
//

import SwiftUI
import SwiftData

struct BrewCoffeePickerView: View {
    let method: BrewMethod

    @Query(filter: #Predicate<Coffee> { $0.archivedAt == nil },
           sort: \Coffee.createdAt, order: .reverse) private var coffees: [Coffee]

    var body: some View {
        List {
            ForEach(coffees) { coffee in
                NavigationLink(value: BrewStep.setup(coffee, method)) {
                    CoffeeCardView(coffee: coffee)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Chooses this coffee to brew")
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color("CoffeeCanvas"))
        .overlay {
            if coffees.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("Nothing to brew yet")
                    } icon: {
                        Image("CoffeeBeansDuotone")
                            .resizable().scaledToFit()
                            .frame(width: 72, height: 72)
                            .accessibilityHidden(true)
                    }
                } description: {
                    Text("Add a coffee in your library first.")
                }
            }
        }
        .navigationTitle("Choose a coffee")
        .navigationBarTitleDisplayMode(.inline)
    }
}
