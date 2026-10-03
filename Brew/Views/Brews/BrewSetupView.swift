//
//  BrewSetupView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 19/09/26.
//

import SwiftUI
import SwiftData

struct BrewSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var setup: BrewSetupViewModel
    @State private var showsSaveError = false

    private let onSaved: (Brew) -> Void

    init(setup: BrewSetupViewModel, onSaved: @escaping (Brew) -> Void) {
        self.onSaved = onSaved
        _setup = State(initialValue: setup)
    }

    var body: some View {
        Form {
            if let suggestion = setup.suggestion, setup.adjustment == nil {
                Section {
                    suggestionRow(suggestion)
                }
            }

            Section {
                HStack(spacing: 12) {
                    Image(setup.method.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .accessibilityHidden(true)

                    Text(setup.method.title)
                        .font(.headline)
                }
                .padding(.vertical, 4)
            }

            Section {
                LabeledContent("Coffee") {
                    amountField("18", value: $setup.coffeeGrams, unit: "g")
                }

                if setup.usesBeverageYield {
                    LabeledContent("Beverage") {
                        amountField("36", value: $setup.beverageGrams, unit: "g")
                    }
                } else {
                    LabeledContent("Water") {
                        amountField("300", value: $setup.waterGrams, unit: "g")
                    }
                }

                LabeledContent("Temperature") {
                    amountField("93", value: $setup.temperatureCelsius, unit: "°C")
                }

                if let ratio = setup.ratio {
                    LabeledContent("Ratio", value: "1:\(ratio.formatted(.number.precision(.fractionLength(1))))")
                }
            } header: {
                Text("Dose")
            } footer: {
                if let adjustment = setup.adjustment, adjustment.variable != .grind {
                    adjustmentFooter(adjustment)
                }
            }

            Section {
                TextField("22 clicks, 4.2, or medium-fine", text: $setup.grindDisplayValue)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Grind setting")
            } footer: {
                if let adjustment = setup.adjustment, adjustment.variable == .grind {
                    adjustmentFooter(adjustment)
                }
            }

            Section("Time") {
                LabeledContent("Target time") {
                    HStack(spacing: 4) {
                        TextField("2", value: $setup.durationMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 44)
                        Text("min")
                            .foregroundStyle(.secondary)
                        TextField("45", value: $setup.durationSeconds, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 44)
                        Text("s")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("CoffeeCanvas"))
        .navigationTitle(setup.coffee.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    if let brew = setup.saveDraft(in: modelContext) {
                        onSaved(brew)
                    } else {
                        showsSaveError = true
                    }
                }
                .disabled(!setup.canSave)
            }
        }
        .alert("Couldn't save brew", isPresented: $showsSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your brew couldn't be saved. Please try again.")
        }
    }

    private func suggestionRow(_ suggestion: BrewSuggestion) -> some View {
        Button {
            setup.applySuggestion()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(suggestion.adjustment.title) than \(suggestion.adjustment.previousDisplayValue)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    Text("After your brew on \(suggestion.source.sortDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("Apply")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("CoffeeTint"))
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Fills this setup with the suggested change")
    }

    private func adjustmentFooter(_ adjustment: BrewAdjustment) -> some View {
        Label(
            "Previously \(adjustment.previousDisplayValue) · \(adjustment.title)",
            systemImage: "arrow.triangle.2.circlepath")
            .font(.footnote)
            .foregroundStyle(Color("CoffeeTint"))
    }

    private func amountField(_ placeholder: String, value: Binding<Double?>, unit: LocalizedStringKey) -> some View {
        HStack {
            TextField(placeholder, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}
