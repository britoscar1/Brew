//
//  BrewView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import SwiftUI
import SwiftData


struct BrewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path: [BrewStep] = []
    @State private var showsDiscardConfirmation = false
    @Query(filter: #Predicate<Coffee> { $0.archivedAt == nil }) private var coffees: [Coffee]
    @Query private var brews: [Brew]

    private let spacing: CGFloat = 14

    private var methodRows: [[BrewMethod]] {
        stride(from: 0, to: BrewMethod.allCases.count, by: 2).map {
            Array(BrewMethod.allCases[$0 ..< min($0 + 2, BrewMethod.allCases.count)])
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
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
                } else {
                    VStack(spacing: spacing) {
                        if let pending {
                            unfinishedBrewCard(pending)
                        }

                        methodGrid
                    }
                    .padding(16)
                }
            }
            .background(Color("CoffeeCanvas"))
            .confirmationDialog("Discard this brew?", isPresented: $showsDiscardConfirmation,
                                titleVisibility: .visible) {
                Button("Discard", role: .destructive) {
                    if let pending { InterruptedBrews.discard(pending, in: modelContext) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("It was never finished, so it is not in your history. This cannot be undone.")
            }
            .brewFlow(path: $path) { path.removeAll() }
            .navigationTitle("How are you brewing?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Only the newest one: discarding it brings up the next, so they drain
    /// instead of piling up behind a counter.
    private var pending: Brew? {
        InterruptedBrews.pending(in: brews).first
    }

    private func unfinishedBrewCard(_ brew: Brew) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Unfinished · \(brew.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(summary(of: brew))
                    .font(.subheadline.weight(.medium))
            }

            Spacer(minLength: 0)

            Button("Discard") { showsDiscardConfirmation = true }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Continue") { path.append(.brewMode(brew)) }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(14)
        .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("CoffeeTint").opacity(0.12))
        }
    }

    private func summary(of brew: Brew) -> String {
        [brew.method?.title, brew.coffee?.name]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private var methodGrid: some View {
        VStack(spacing: spacing) {
            ForEach(methodRows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row) { method in
                        NavigationLink(value: BrewStep.chooseCoffee(method)) {
                            MethodCard(method: method)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MethodCard: View {
    let method: BrewMethod

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            Image(method.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(method.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color("CoffeeTint").opacity(0.12))
        }
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let dose = method.defaults.coffeeGrams.formatted(.number.precision(.fractionLength(0...1)))
        let ratio = method.defaultRatio.formatted(.number.precision(.fractionLength(0...1)))
        return "\(dose) g · 1:\(ratio)"
    }
}
