//
//  BrewView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import SwiftUI
import SwiftData

enum BrewStep: Hashable {
    case chooseCoffee(BrewMethod)
    case setup(Coffee, BrewMethod)
    case brewMode(Brew)
    case evaluate(Brew)
    case recommendation(Brew)
}

struct BrewView: View {
    @State private var path: [BrewStep] = []
    @Query(filter: #Predicate<Coffee> { $0.archivedAt == nil }) private var coffees: [Coffee]

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
                    methodGrid
                }
            }
            .background(Color("CoffeeCanvas"))
            .navigationDestination(for: BrewStep.self) { step in
                switch step {
                case let .chooseCoffee(method):
                    BrewCoffeePickerView(method: method)
                case let .setup(coffee, method):
                    BrewSetupView(setup: BrewSetupViewModel(coffee: coffee, method: method)) { brew in
                        path.append(.brewMode(brew))
                    }
                case let .brewMode(brew):
                    BrewModeView(brew: brew) { path = [.evaluate($0)] }
                case let .evaluate(brew):
                    TasteEvaluationView(brew: brew) { path.append(.recommendation($0)) }
                case let .recommendation(brew):
                    RecommendationView(brew: brew) { path.removeAll() }
                }
            }
            .navigationTitle("How are you brewing?")
            .navigationBarTitleDisplayMode(.inline)
        }
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
        .padding(16)
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
