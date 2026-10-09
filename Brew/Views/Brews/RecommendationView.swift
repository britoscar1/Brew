//
//  RecommendationView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import SwiftUI

struct RecommendationView: View {
    let brew: Brew
    let onFinish: () -> Void
    var onEdit: (() -> Void)?
    var onBrewAgain: ((Bool) -> Void)?

    var body: some View {
        ScrollView {
            if let recommendation = brew.recommendation {
                VStack(alignment: .leading, spacing: 24) {
                    RecommendationCard(brew: brew, recommendation: recommendation)

                    section(title: "Why") {
                        Text(recommendation.explanation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(Color("CoffeeCrema").opacity(0.2),
                                        in: RoundedRectangle(cornerRadius: 20))
                    }

                    if !settings.isEmpty {
                        section(title: settingsTitle(for: recommendation)) {
                            BrewSettingsCard(settings: settings)
                        }
                    }

                    if let onBrewAgain, canBrewAgain {
                        VStack(spacing: 12) {
                            if adjustment != nil {
                                Button {
                                    onBrewAgain(true)
                                } label: {
                                    Text("Brew with this adjustment").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }

                            Button {
                                onBrewAgain(false)
                            } label: {
                                Text("Repeat brew").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color("CoffeeCanvas"))
        .navigationTitle("Next time")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            if let onEdit {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit", systemImage: "pencil", action: onEdit)
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: onFinish)
            }
        }
    }

    private var adjustment: BrewAdjustment? {
        BrewAdjustment(brew: brew)
    }

    private var canBrewAgain: Bool {
        guard let coffee = brew.coffee else { return false }
        return coffee.archivedAt == nil && brew.method != nil
    }

    private var settings: [BrewSetting] {
        guard let recommendation = brew.recommendation else { return [] }
        return BrewSetting.all(for: brew, recommendation: recommendation)
    }

    private func settingsTitle(for recommendation: BrewRecommendation) -> LocalizedStringKey {
        recommendation.direction == .maintain || recommendation.direction == .unclear
            ? "Brew settings"
            : "Keep the rest the same"
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
