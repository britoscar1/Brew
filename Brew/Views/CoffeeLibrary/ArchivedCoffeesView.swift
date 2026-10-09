//
//  ArchivedCoffeesView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import SwiftUI
import SwiftData

struct ArchivedCoffeesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showsSaveError = false
    @Query(filter: #Predicate<Coffee> { $0.archivedAt != nil },
           sort: \Coffee.archivedAt, order: .reverse) private var coffees: [Coffee]

    var body: some View {
        List {
            ForEach(coffees) { coffee in
                NavigationLink {
                    CoffeeDetailView(coffee: coffee)
                } label: {
                    CoffeeCardView(coffee: coffee)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens coffee details")
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions {
                    Button {
                        restore(coffee)
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                    .tint(Color("CoffeeTint"))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color("CoffeeCanvas"))
        .overlay {
            if coffees.isEmpty {
                ContentUnavailableView(
                    "No archived coffees",
                    systemImage: "archivebox",
                    description: Text("Coffees you archive stay here with their history.")
                )
            }
        }
        .persistenceErrorAlert(isPresented: $showsSaveError)
        .navigationTitle("Archived")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func restore(_ coffee: Coffee) {
        showsSaveError = !coffee.restore(in: modelContext)
    }
}
