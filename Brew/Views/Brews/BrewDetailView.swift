//
//  BrewDetailView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 01/10/26.
//

import SwiftUI

struct BrewDetailView: View {
    let brew: Brew

    @State private var showsEvaluation = false

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

                section(title: "Taste") {
                    taste
                }

                if let recommendation = brew.recommendation {
                    section(title: "Next time") {
                        VStack(alignment: .leading, spacing: 18) {
                            RecommendationCard(brew: brew, recommendation: recommendation)

                            Text(recommendation.explanation)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(18)
                                .background(Color("CoffeeCrema").opacity(0.2),
                                            in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
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
            if brew.tasteEvaluation != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit evaluation", systemImage: "pencil") {
                        showsEvaluation = true
                    }
                }
            }
        }
        .sheet(isPresented: $showsEvaluation) {
            EvaluationFlow(brew: brew) { showsEvaluation = false }
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
                    showsEvaluation = true
                } label: {
                    Text("Evaluate").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
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
