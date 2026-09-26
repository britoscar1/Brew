//
//  EvaluationFlow.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import SwiftUI

private enum EvaluationFlowStep: Hashable {
    case evaluation
    case recommendation
}

struct EvaluationFlow: View {
    let brew: Brew
    let onFinish: () -> Void

    @State private var path: [EvaluationFlowStep] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if brew.recommendation != nil {
                    RecommendationView(
                        brew: brew,
                        onFinish: onFinish,
                        onEdit: { path.append(.evaluation) }
                    )
                } else {
                    evaluationView
                }
            }
            .navigationDestination(for: EvaluationFlowStep.self) { step in
                switch step {
                case .evaluation:
                    evaluationView
                case .recommendation:
                    RecommendationView(brew: brew, onFinish: onFinish)
                }
            }
            .toolbar {
                if brew.recommendation == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onFinish)
                    }
                }
            }
        }
        .tint(Color("CoffeeTint"))
    }

    private var evaluationView: some View {
        TasteEvaluationView(brew: brew) { _ in
            path.append(.recommendation)
        }
    }
}
