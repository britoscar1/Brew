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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var path: [BrewStep] = []
    @State private var showsSaveError = false
    @State private var showsDiscardConfirmation = false
    @Query(filter: #Predicate<Coffee> { $0.archivedAt == nil }) private var coffees: [Coffee]
    @Query private var brews: [Brew]

    private let spacing: CGFloat = 14

    private var methodRows: [[BrewMethod]] {
        let perRow = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return stride(from: 0, to: BrewMethod.allCases.count, by: perRow).map {
            Array(BrewMethod.allCases[$0 ..< min($0 + perRow, BrewMethod.allCases.count)])
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if coffees.isEmpty && pending == nil {
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
                } else if dynamicTypeSize.isAccessibilitySize {
                    ScrollView {
                        brewOptions
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    brewOptions
                }
            }
            .background(Color("CoffeeCanvas"))
            .confirmationDialog("Discard this brew?", isPresented: $showsDiscardConfirmation,
                                titleVisibility: .visible) {
                Button("Discard", role: .destructive) {
                    if let pending { showsSaveError = !InterruptedBrews.discard(pending, in: modelContext) }
                }
                .accessibilityIdentifier("pending.confirmDiscard")
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("It was never finished, so it is not in your history. This cannot be undone.")
            }
            .persistenceErrorAlert(isPresented: $showsSaveError)
            .brewFlow(path: $path) { path.removeAll() }
            .navigationTitle("How are you brewing?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var brewOptions: some View {
        VStack(spacing: spacing) {
            if let pending {
                unfinishedBrewCard(pending)
            }

            if coffees.isEmpty {
                Text("Restore a coffee in your library to start a new brew.")
                    .foregroundStyle(.secondary)
            } else {
                methodGrid
            }
        }
        .padding(16)
    }

    private var pending: Brew? {
        InterruptedBrews.pending(in: brews).first
    }

    private func unfinishedBrewCard(_ brew: Brew) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))

        return layout {
            VStack(alignment: .leading, spacing: 2) {
                Text("Unfinished · \(brew.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(summary(of: brew))
                    .font(.subheadline.weight(.medium))
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button("Discard") { showsDiscardConfirmation = true }
                    .accessibilityIdentifier("pending.discard")
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Continue") { path.append(.brewMode(brew)) }
                    .accessibilityIdentifier("pending.continue")
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
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
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
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
