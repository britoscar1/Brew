//
//  CoffeeLibraryView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import SwiftUI
import SwiftData

struct CoffeeLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Coffee> { $0.archivedAt == nil },
           sort: \Coffee.createdAt, order: .reverse) private var coffees: [Coffee]
    @State private var showsAddCoffee = false
    @State private var coffeeToArchive: Coffee?

    var body: some View {
        NavigationStack {
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
                    .swipeActions(allowsFullSwipe: false) {
                        Button {
                            coffeeToArchive = coffee
                        } label: {
                            Label("Archive", systemImage: "archivebox")
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
                    ContentUnavailableView {
                        Label {
                            Text("No coffees yet")
                        } icon: {
                            Image("CoffeeBeansDuotone")
                                .resizable().scaledToFit()
                                .frame(width: 72, height: 72)
                                .accessibilityHidden(true)
                        }
                    } description: {
                        Text("Keep the coffees you enjoy in one place.")
                    } actions: {
                        Button {
                            showsAddCoffee = true
                        } label: {
                            Text("Add your first coffee")
                                .foregroundStyle(Color("CoffeeCanvas"))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .navigationTitle("Your coffees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        ArchivedCoffeesView()
                    } label: {
                        Label("Archived Coffees", systemImage: "archivebox")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Coffee", systemImage: "plus") { showsAddCoffee = true }
                }
            }
            .sheet(isPresented: $showsAddCoffee) { CoffeeFormView() }
            .confirmationDialog(
                "Archive \(coffeeToArchive?.name ?? "")?",
                isPresented: .init(get: { coffeeToArchive != nil },
                                   set: { if !$0 { coffeeToArchive = nil } }),
                titleVisibility: .visible
            ) {
                Button("Archive") {
                    if let coffeeToArchive { archive(coffeeToArchive) }
                    coffeeToArchive = nil
                }
                Button("Cancel", role: .cancel) { coffeeToArchive = nil }
            } message: {
                Text("You can restore it later from Archived Coffees.")
            }
        }
    }

    private func archive(_ coffee: Coffee) {
        coffee.archive()
        try? modelContext.save()
    }
}
