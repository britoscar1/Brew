//
//  BrewFlow.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 08/10/26.
//

import SwiftUI

enum BrewStep: Hashable {
    case chooseCoffee(BrewMethod)
    case setup(Coffee, BrewMethod)
    case repeatSetup(Brew, applyingAdjustment: Bool)
    case brewMode(Brew)
    case evaluate(Brew)
    case recommendation(Brew)
}

extension View {
    /// Registers every step a brew goes through, once. Both entry points — the
    /// Brew tab and repeating one from its detail — run this same flow, so
    /// finishing a brew always lands on its recommendation.
    func brewFlow(path: Binding<[BrewStep]>, onFinish: @escaping () -> Void) -> some View {
        modifier(BrewFlowDestinations(path: path, onFinish: onFinish))
    }
}

private struct BrewFlowDestinations: ViewModifier {
    @Binding var path: [BrewStep]
    let onFinish: () -> Void

    func body(content: Content) -> some View {
        content.navigationDestination(for: BrewStep.self) { step in
            switch step {
            case let .chooseCoffee(method):
                BrewCoffeePickerView(method: method)

            case let .setup(coffee, method):
                BrewSetupView(setup: BrewSetupViewModel(coffee: coffee, method: method)) {
                    path.append(.brewMode($0))
                }

            case let .repeatSetup(source, applyingAdjustment):
                if let setup = BrewSetupViewModel(
                    repeating: source,
                    adjustment: applyingAdjustment ? BrewAdjustment(brew: source) : nil) {
                    BrewSetupView(setup: setup) { path.append(.brewMode($0)) }
                }

            case let .brewMode(brew):
                BrewModeView(brew: brew) { path = [.evaluate($0)] }

            case let .evaluate(brew):
                // The brew is already done: there is nothing to go back to.
                TasteEvaluationView(brew: brew) { path.append(.recommendation($0)) }
                    .navigationBarBackButtonHidden()

            case let .recommendation(brew):
                RecommendationView(
                    brew: brew,
                    onFinish: onFinish,
                    onBrewAgain: { applying in
                        path = [.repeatSetup(brew, applyingAdjustment: applying)]
                    })
            }
        }
    }
}
