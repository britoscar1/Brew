//
//  TasteEvaluationView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import SwiftUI
import SwiftData

struct TasteEvaluationView: View {
    let brew: Brew
    let onSaved: (Brew) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var evaluation: TasteEvaluationViewModel
    @State private var showsSaveError = false

    init(brew: Brew, onSaved: @escaping (Brew) -> Void) {
        self.brew = brew
        self.onSaved = onSaved
        _evaluation = State(initialValue: TasteEvaluationViewModel(brew: brew))
    }

    var body: some View {
        Form {
            Section {
                TasteScale(title: "Acidity",
                           labels: ["Flat", "Low", "Balanced", "Bright", "Sharp"],
                           style: .position,
                           value: $evaluation.acidityValue)

                TasteScale(title: "Bitterness",
                           labels: ["None", "Low", "Balanced", "Bitter", "Harsh"],
                           style: .position,
                           value: $evaluation.bitternessValue)

                TasteScale(title: "Strength",
                           labels: ["Watery", "Weak", "Balanced", "Strong", "Intense"],
                           style: .position,
                           value: $evaluation.strengthValue)
            } header: {
                Text("How did it taste?")
            }

            Section("Overall") {
                TasteScale(title: "How much you liked it",
                           labels: ["Disliked", "Poor", "Okay", "Good", "Loved"],
                           style: .rating,
                           value: $evaluation.overallValue)
            }

            Section {
                Picker("Next time", selection: $evaluation.improvementGoal) {
                    Text("No change").tag(nil as ImprovementGoal?)
                    ForEach(ImprovementGoal.allCases) { goal in
                        Text(goal.title).tag(Optional(goal))
                    }
                }
            } header: {
                Text("What would you improve?")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("CoffeeCanvas"))
        .navigationTitle(evaluation.isEditing ? "Edit Evaluation" : "Evaluate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if evaluation.save(in: modelContext) {
                        onSaved(brew)
                    } else {
                        showsSaveError = true
                    }
                }
            }
        }
        .alert("Couldn't save evaluation", isPresented: $showsSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your evaluation couldn't be saved. Please try again.")
        }
    }
}
