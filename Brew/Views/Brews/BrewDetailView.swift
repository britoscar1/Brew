//
//  BrewDetailView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 01/10/26.
//

import SwiftUI
import SwiftData

private struct RepeatRequest: Identifiable {
    let brew: Brew
    let appliesAdjustment: Bool

    var id: String { "\(brew.persistentModelID)-\(appliesAdjustment)" }
}

struct BrewDetailView: View {
    let brew: Brew

    @Environment(\.modelContext) private var modelContext
    @State private var showsSaveError = false
    @State private var brewToEvaluate: Brew?
    @State private var positionToReplace: Int?
    @State private var repeatRequest: RepeatRequest?
    @State private var flowPath: [BrewStep] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                section(title: "Brew settings") {
                    BrewSettingsCard(settings: settings)
                }

                if !timing.isEmpty {
                    section(title: "Timing") {
                        BrewSettingsCard(settings: timing)
                    }
                }

                tasteSection

                if let recommendation = brew.recommendation {
                    section(title: "Next time") {
                        VStack(alignment: .leading, spacing: 18) {
                            RecommendationCard(brew: brew, recommendation: recommendation)

                            Text(recommendation.explanation)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(18)
                                .background(Color("CoffeeCrema").opacity(0.2),
                                            in: RoundedRectangle(cornerRadius: 20))

                            if canRepeat, adjustment != nil {
                                Button {
                                    repeatRequest = RepeatRequest(brew: brew, appliesAdjustment: true)
                                } label: {
                                    Text("Brew with this adjustment").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                        }
                    }
                }

                if canRepeat {
                    Button {
                        repeatRequest = RepeatRequest(brew: brew, appliesAdjustment: false)
                    } label: {
                        Text("Repeat brew").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("brew.repeat")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Color("CoffeeCanvas"))
        .navigationTitle("Brew")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let top, top.canHoldAPosition(brew) {
                ToolbarItem(placement: .primaryAction) {
                    topBrewsMenu(top)
                }
            }
        }
        .confirmationDialog(
            "Replace position \(positionToReplace ?? 0)?",
            isPresented: Binding(get: { positionToReplace != nil },
                                 set: { if !$0 { positionToReplace = nil } }),
            titleVisibility: .visible
        ) {
            Button("Replace") {
                if let top, let position = positionToReplace {
                    showsSaveError = !top.assign(brew, to: position, in: modelContext)
                }
                positionToReplace = nil
            }
            Button("Cancel", role: .cancel) { positionToReplace = nil }
        } message: {
            Text("The brew there leaves the Top 3 and stays in your history.")
        }
        .persistenceErrorAlert(isPresented: $showsSaveError)
        .sheet(item: $brewToEvaluate) { target in
            NavigationStack {
                TasteEvaluationView(brew: target) { _ in brewToEvaluate = nil }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { brewToEvaluate = nil }
                        }
                    }
            }
            .tint(Color("CoffeeTint"))
        }
        .fullScreenCover(item: $repeatRequest) { request in
            if let setup = BrewSetupViewModel(repeating: request.brew,
                                              adjustment: request.appliesAdjustment ? adjustment : nil) {
                NavigationStack(path: $flowPath) {
                    BrewSetupView(setup: setup) { flowPath.append(.brewMode($0)) }
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel", action: closeBrewFlow)
                            }
                        }
                        .brewFlow(path: $flowPath, onFinish: closeBrewFlow)
                }
                .tint(Color("CoffeeTint"))
            }
        }
    }

    private func closeBrewFlow() {
        flowPath.removeAll()
        repeatRequest = nil
    }

    private var top: TopBrewsManager? {
        guard let coffee = brew.coffee, coffee.archivedAt == nil else { return nil }
        return TopBrewsManager(coffee: coffee)
    }

    private func topBrewsMenu(_ top: TopBrewsManager) -> some View {
        Menu {
            ForEach(TopBrewsManager.positions, id: \.self) { position in
                Button {
                    choose(position, in: top)
                } label: {
                    if brew.topBrewRank == position {
                        Label("Position \(position)", systemImage: "checkmark")
                    } else if let occupant = top.brew(at: position) {
                        Text("Position \(position)")
                        Text("Replaces \(occupant.sortDate.formatted(.dateTime.month(.abbreviated).day()))")
                    } else {
                        Text("Position \(position)")
                    }
                }
            }

            if brew.topBrewRank != nil {
                Section {
                    Button("Remove from Top 3", systemImage: "star.slash", role: .destructive) {
                        showsSaveError = !top.remove(brew, in: modelContext)
                    }
                }
            }
        } label: {
            Label("Top 3", systemImage: brew.topBrewRank == nil ? "star" : "star.fill")
        }
    }

    private func choose(_ position: Int, in top: TopBrewsManager) {
        guard brew.topBrewRank != position else { return }

        if top.brew(at: position) == nil {
            showsSaveError = !top.assign(brew, to: position, in: modelContext)
        } else {
            positionToReplace = position
        }
    }

    private var adjustment: BrewAdjustment? {
        BrewAdjustment(brew: brew)
    }

    private var canRepeat: Bool {
        guard let coffee = brew.coffee else { return false }
        return coffee.archivedAt == nil && brew.method != nil
    }

    private var tasteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Taste")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if brew.tasteEvaluation != nil {
                    Button("Edit") { brewToEvaluate = brew }
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 4)

            taste
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            if let method = brew.method {
                Image(method.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(brew.coffee?.name ?? String(localized: "Coffee"))
                    .font(.headline)

                Text(brew.method?.title ?? String(localized: "Unknown method"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(brew.sortDate, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var taste: some View {
        if let evaluation = brew.tasteEvaluation {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(TasteDimension.allCases, id: \.self) { dimension in
                    TasteScale(dimension: dimension, value: dimension.value(in: evaluation))
                }

                if let notes = evaluation.notes {
                    Divider().padding(.vertical, 8)
                    Text(notes)
                        .font(.subheadline)
                        .accessibilityIdentifier("brew.tasteNotes")
                }

                if let goal = evaluation.improvementGoal {
                    Divider()
                        .padding(.vertical, 8)

                    LabeledContent("Wanted to improve") {
                        Text(goal.title)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(18)
            .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
        } else {
            VStack(spacing: 14) {
                Text("This brew hasn't been evaluated yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    brewToEvaluate = brew
                } label: {
                    Text("Evaluate").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("brew.evaluate")
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var settings: [BrewSetting] {
        var items = BrewSetting.all(for: brew)

        if let ratio = brew.ratio {
            items.append(BrewSetting(
                title: String(localized: "Ratio"),
                value: "1:\(ratio.formatted(.number.precision(.fractionLength(1))))",
                icon: "divide"))
        }

        return items
    }

    private var timing: [BrewSetting] {
        var items: [BrewSetting] = []

        if let target = brew.targetDurationSeconds, target > 0 {
            items.append(BrewSetting(title: String(localized: "Target time"),
                                     value: BrewSetting.duration(target), icon: "target"))
        }

        if let actual = brew.actualDurationSeconds, actual > 0 {
            items.append(BrewSetting(title: String(localized: "Actual time"),
                                     value: BrewSetting.duration(actual), icon: "stopwatch"))
        }

        return items
    }

    private func section<Content: View>(title: LocalizedStringKey,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            content()
        }
    }
}
