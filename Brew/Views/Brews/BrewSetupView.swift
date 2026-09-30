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

    private let coffee: Coffee
    private let method: BrewMethod
    private let onSaved: (Brew) -> Void

    init(coffee: Coffee, method: BrewMethod, onSaved: @escaping (Brew) -> Void) {
        self.coffee = coffee
        self.method = method
        self.onSaved = onSaved
        _setup = State(initialValue: BrewSetupViewModel(coffee: coffee, method: method))
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(method.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .accessibilityHidden(true)

                    Text(method.title)
                        .font(.headline)
                }
                .padding(.vertical, 4)
            }

            Section("Dose") {
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
            }

            Section("Grind setting") {
                TextField("22 clicks, 4.2, or medium-fine", text: $setup.grindDisplayValue)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
        .navigationTitle(coffee.name)
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
