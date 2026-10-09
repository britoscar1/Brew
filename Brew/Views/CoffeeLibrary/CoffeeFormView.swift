//
//  CoffeeFormView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import SwiftUI
import SwiftData

struct CoffeeFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var form: CoffeeFormViewModel
    @State private var showsSaveError = false

    private let coffee: Coffee?

    init(coffee: Coffee? = nil) {
        self.coffee = coffee
        _form = State(initialValue: CoffeeFormViewModel(coffee: coffee))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $form.name)
                        .accessibilityIdentifier("coffee.name")
                        .autocorrectionDisabled()
                    TextField("Origin", text: $form.origin)
                        .accessibilityIdentifier("coffee.origin")
                        .autocorrectionDisabled()
                    TextField("Roaster (optional)", text: $form.roaster)
                        .autocorrectionDisabled()
                } header: {
                    Text("Coffee")
                }
                Section("Roast") {
                    Picker("Roast level", selection: $form.roastLevel) {
                        Text("Select roast level").tag(nil as RoastLevel?)
                        ForEach(RoastLevel.allCases) { level in
                            Text(level.title).tag(Optional(level))
                        }
                    }
                    .accessibilityIdentifier("coffee.roast")
                    TextField("Process (optional)", text: $form.process)
                    Toggle("Include roast date", isOn: $form.includesRoastDate)
                    if form.includesRoastDate {
                        DatePicker("Roast date", selection: $form.roastDate, displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextField("Notes (optional)", text: $form.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("CoffeeCanvas"))
            .navigationTitle(coffee == nil ? "Add coffee" : "Edit coffee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if form.save(in: modelContext) {
                            dismiss()
                        } else {
                            showsSaveError = true
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!form.canSave)
                    .accessibilityIdentifier("coffee.save")
                }
            }
            .alert("Couldn't save coffee", isPresented: $showsSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your coffee couldn't be saved. Please try again.")
            }
        }
        .tint(Color("CoffeeTint"))
    }
}

#Preview {
    CoffeeFormView().modelContainer(for: Coffee.self, inMemory: true)
}
