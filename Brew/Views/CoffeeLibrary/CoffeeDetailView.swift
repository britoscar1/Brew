//
//  CoffeeDetailView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import SwiftUI
import SwiftData

private let cardBackground = Color("CoffeeCrema").opacity(0.2)

struct CoffeeDetailView: View {
    let coffee: Coffee

    @Environment(\.modelContext) private var modelContext
    @State private var showsEditCoffee = false
    @State private var showsArchiveConfirmation = false
    @State private var brewToEvaluate: Brew?

    var body: some View {
        List {
            if coffee.archivedAt != nil {
                Section {
                    Label("This coffee is archived", systemImage: "archivebox")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(cardBackground)
            }

            Section {
                header
            }
            .listRowBackground(cardBackground)

            Section("Bean Information") {
                if coffee.roastLevel == nil {
                    LabeledContent("Roast level", value: String(localized: "Unknown roast"))
                }

                if let process = coffee.process {
                    LabeledContent("Process", value: process)
                }

                if let roastDate = coffee.roastDate {
                    LabeledContent("Roast date") {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(roastDate, format: .relative(presentation: .named))
                            Text(roastDate, format: .dateTime.month(.abbreviated).day().year())
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                LabeledContent("Added") {
                    Text(coffee.createdAt, format: .dateTime.month(.abbreviated).day().year())
                }
            }
            .listRowBackground(cardBackground)

            Section("Brew History") {
                if brews.isEmpty {
                    Text("No brews logged yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(brews.prefix(3)) { brew in
                        Button {
                            brewToEvaluate = brew
                        } label: {
                            BrewRow(brew: brew)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(brew.tasteEvaluation == nil ? "Rates this brew" : "Edits this rating")
                    }

                    if brews.count > 3 {
                        NavigationLink {
                            BrewHistoryView(coffee: coffee)
                        } label: {
                            HStack {
                                Text("See all")
                                Spacer()
                                Text("\(brews.count)")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline.weight(.medium))
                        }
                    }
                }
            }
            .listRowBackground(cardBackground)

            if let notes = coffee.notes {
                Section("Notes") {
                    Text(notes)
                }
                .listRowBackground(cardBackground)
            }
        }
        .contentMargins(.top, 12, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color("CoffeeCanvas"))
        .navigationTitle(coffee.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("More", systemImage: "ellipsis.circle") {
                    if coffee.archivedAt == nil {
                        Button("Archive", systemImage: "archivebox") {
                            showsArchiveConfirmation = true
                        }
                    } else {
                        Button("Restore", systemImage: "arrow.uturn.backward") {
                            coffee.restore()
                            try? modelContext.save()
                        }
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Edit", systemImage: "pencil") {
                    showsEditCoffee = true
                }
            }
        }
        .sheet(item: $brewToEvaluate) { brew in
            EvaluationFlow(brew: brew) { brewToEvaluate = nil }
        }
        .sheet(isPresented: $showsEditCoffee) {
            CoffeeFormView(coffee: coffee)
        }
        .confirmationDialog(
            "Archive \(coffee.name)?",
            isPresented: $showsArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive") {
                coffee.archive()
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can restore it later from Archived Coffees.")
        }
    }

    private var brews: [Brew] {
        coffee.completedBrews
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let roaster = coffee.roaster {
                        Text(roaster)
                    }

                    Label(coffee.origin, systemImage: "mappin.and.ellipse")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Image("CoffeeBeansDuotone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .accessibilityHidden(true)
            }

            if let roastLevel = coffee.roastLevel {
                VStack(alignment: .leading, spacing: 8) {
                    Text(roastLevel.title)
                        .font(.subheadline.weight(.medium))

                    RoastLevelScale(level: roastLevel)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct BrewHistoryView: View {
    let coffee: Coffee

    @State private var brewToEvaluate: Brew?

    var body: some View {
        List {
            ForEach(brews) { brew in
                Button {
                    brewToEvaluate = brew
                } label: {
                    BrewRow(brew: brew)
                }
                .buttonStyle(.plain)
                .accessibilityHint(brew.tasteEvaluation == nil ? "Rates this brew" : "Shows its recommendation")
            }
        }
        .contentMargins(.top, 12, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color("CoffeeCanvas"))
        .navigationTitle("Brew History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $brewToEvaluate) { brew in
            EvaluationFlow(brew: brew) { brewToEvaluate = nil }
        }
    }

    private var brews: [Brew] {
        coffee.completedBrews
    }
}

#Preview {
    NavigationStack {
        CoffeeDetailView(
            coffee: Coffee(
                name: "Ethiopia Guji",
                origin: "Ethiopia",
                roastLevel: .mediumLight,
                roaster: "Sample Roaster",
                process: "Natural",
                notes: "Floral, peach and bergamot.",
                roastDate: .now.addingTimeInterval(-12 * 24 * 60 * 60)
            )
        )
    }
    .modelContainer(for: Coffee.self, inMemory: true)
}
