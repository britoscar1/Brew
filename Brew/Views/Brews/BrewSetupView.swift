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
    @FocusState private var grindIsFocused: Bool
    @FocusState private var numericField: String?

    private let onSaved: (Brew) -> Void

    init(setup: BrewSetupViewModel, onSaved: @escaping (Brew) -> Void) {
        self.onSaved = onSaved
        _setup = State(initialValue: setup)
    }

    var body: some View {
        Form {
            Section {
                Picker("Recipe", selection: Binding(
                    get: { setup.selectedRecipeID ?? (setup.selectedRecipeName != nil ? "copied" : nil) },
                    set: { if $0 != "copied" { setup.selectRecipe($0) } }
                )) {
                    Text("Manual setup").tag(nil as String?)
                    Text(setup.starterRecipe.name).tag(Optional(setup.starterRecipe.id))
                    if setup.selectedRecipeID == nil, setup.selectedRecipeName != nil {
                        Text("Copied recipe").tag(Optional("copied"))
                    }
                }
                .accessibilityIdentifier("setup.recipe")

                if setup.selectedRecipeID == nil, let name = setup.selectedRecipeName {
                    Text("Copied from \(name)").font(.subheadline).foregroundStyle(.secondary)
                }

                if !setup.guidedSteps.isEmpty {
                    DisclosureGroup("Recipe steps") {
                        ForEach(setup.guidedSteps) { step in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(BrewSetting.duration(step.startsAtSeconds)) · \(step.title)")
                                    .font(.subheadline.weight(.medium))
                                Text(step.instruction)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                if let water = step.cumulativeWaterGrams {
                                    Text("Total water: \(BrewSetting.grams(water))")
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Recipe")
            } footer: {
                Text("Starter recipes are a starting point. Review the amounts and grind for your equipment. Step targets follow your water and target time.")
            }

            if let suggestion = setup.suggestion, !setup.hasAppliedSuggestion {
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
                    amountField("18", id: "setup.coffee", value: $setup.coffeeGrams, unit: "g")
                }

                if setup.usesBeverageYield {
                    LabeledContent("Beverage") {
                        amountField("36", id: "setup.beverage", value: $setup.beverageGrams, unit: "g")
                    }
                } else {
                    LabeledContent("Water") {
                        amountField("300", id: "setup.water", value: $setup.waterGrams, unit: "g")
                    }
                }

                LabeledContent("Temperature") {
                    amountField("93", id: "setup.temperature", value: $setup.temperatureCelsius, unit: "°C")
                }

                if let ratio = setup.ratio {
                    LabeledContent("Ratio", value: "1:\(ratio.formatted(.number.precision(.fractionLength(1))))")
                }
            } header: {
                Text("Dose")
            } footer: {
                Text("Use positive amounts: coffee up to 500 g, water or beverage up to 10,000 g, and temperature from 1–100 °C. Espresso temperature is optional.")
                if let adjustment = setup.adjustment, adjustment.variable != .grind {
                    adjustmentHint(adjustment)
                }
            }

            Section {
                TextField("22 clicks, 4.2, or medium-fine", text: $setup.grindDisplayValue)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($grindIsFocused)
                    .accessibilityIdentifier("setup.grind")
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Grind setting")

                    Spacer(minLength: 8)

                    if let adjustment = setup.adjustment, adjustment.variable == .grind {
                        adjustmentHint(adjustment)
                    }
                }
            }

            Section {
                LabeledContent("Target time") {
                    HStack(spacing: 4) {
                        TextField("2", value: $setup.durationMinutes, format: .number)
                            .accessibilityIdentifier("setup.minutes")
                            .focused($numericField, equals: "setup.minutes")
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 44)
                        Text("min")
                            .foregroundStyle(.secondary)
                        TextField("45", value: $setup.durationSeconds, format: .number)
                            .accessibilityIdentifier("setup.seconds")
                            .focused($numericField, equals: "setup.seconds")
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 44)
                        Text("s")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Time")
            } footer: {
                Text("Use 0–59 seconds and a total target up to 120 minutes. Leave target time empty if you don't need it.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("CoffeeCanvas"))
        .navigationTitle(setup.coffee.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    grindIsFocused = false
                    numericField = nil
                }
                .accessibilityIdentifier("setup.keyboardDone")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Continue") {
                    if let brew = setup.saveDraft(in: modelContext) {
                        onSaved(brew)
                    } else {
                        showsSaveError = true
                    }
                }
                .disabled(!setup.canSave)
                .accessibilityIdentifier("setup.continue")
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

            if setup.adjustment?.variable == .grind {
                grindIsFocused = true
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    Text("After your brew on \(suggestion.source.sortDate.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("Use")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("CoffeeTint"))
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Sets up this brew from the last one, with the suggested change")
    }

    private func adjustmentHint(_ adjustment: BrewAdjustment) -> some View {
        Text("Previously \(adjustment.previousDisplayValue) · \(adjustment.title)")
            .font(.footnote)
            .foregroundStyle(Color("CoffeeTint"))
            .textCase(nil)
    }

    private func amountField(_ placeholder: String, id: String, value: Binding<Double?>, unit: LocalizedStringKey) -> some View {
        HStack {
            TextField(placeholder, value: value, format: .number)
                .accessibilityIdentifier(id)
                .focused($numericField, equals: id)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}
