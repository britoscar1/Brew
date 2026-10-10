//
//  BrewModeView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 29/09/26.
//

import SwiftUI
import SwiftData

struct BrewModeView: View {
    let brew: Brew
    let onFinished: (Brew) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var session: BrewSessionController?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header

                timer

                guide

                details

            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color("CoffeeCanvas"))
        .safeAreaInset(edge: .bottom) {
            controls
                .padding(16)
                .background(Color("CoffeeCanvas"))
        }
        .navigationTitle("Brew")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(brew.status == .inProgress)
        .task {
            session = BrewSessionController(brew: brew, context: modelContext)
        }
        .alert("Couldn't save brew", isPresented: saveFailedBinding) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your brew couldn't be saved. Please try again.")
        }
    }

    @ViewBuilder
    private var guide: some View {
        if !brew.guidedSteps.isEmpty {
            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                let elapsed = brew.elapsedSeconds(at: timeline.date)
                let guide = BrewGuide(steps: brew.guidedSteps)
                VStack(alignment: .leading, spacing: 12) {
                    if let name = brew.recipeName { Text(name).font(.subheadline).foregroundStyle(.secondary) }
                    if let step = guide.current(at: elapsed) {
                        Text(step.title)
                            .font(.title2.weight(.semibold))
                            .accessibilityIdentifier("guide.currentStep")
                        Text(step.instruction)
                        if let water = step.cumulativeWaterGrams {
                            Text("Total water: \(BrewSetting.grams(water))")
                                .font(.subheadline.weight(.semibold))
                        }
                        if brew.method == .espresso, let yield = brew.beverageGrams {
                            Text("Beverage target: \(BrewSetting.grams(yield))")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    if let next = guide.next(at: elapsed) {
                        Text("Next: \(next.title) at \(BrewSetting.duration(next.startsAtSeconds))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("guide.nextStep")
                    }
                    if brew.status != .draft, let target = brew.targetDurationSeconds, elapsed >= target {
                        Text("Target time reached. Finish when your coffee is ready.")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private var saveFailedBinding: Binding<Bool> {
        Binding(
            get: { session?.saveFailed ?? false },
            set: { session?.saveFailed = $0 }
        )
    }

    private var header: some View {
        VStack(spacing: 6) {
            if let method = brew.method {
                Image(method.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .accessibilityHidden(true)

                Text(method.title)
                    .font(.headline)
            }

            if let coffee = brew.coffee {
                Text(coffee.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var timer: some View {
        VStack(spacing: 6) {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                Text(BrewSetting.duration(brew.elapsedSeconds(at: context.date)))
                    .font(.system(size: 72, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(session?.isPaused == true ? .secondary : .primary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(session?.isPaused == true
                                        ? Text("Elapsed time, paused")
                                        : Text("Elapsed time"))
                    .accessibilityValue(elapsedDescription(at: context.date))
            }

            if session?.isPaused == true {
                Text("Paused")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private func elapsedDescription(at date: Date) -> Text {
        let total = Int(brew.elapsedSeconds(at: date))
        return Text(Duration.seconds(total)
            .formatted(.units(allowed: [.minutes, .seconds], width: .wide)))
    }

    private var details: some View {
        BrewSettingsCard(settings: settings)
    }

    private var settings: [BrewSetting] {
        var items: [BrewSetting] = []

        if let target = brew.targetDurationSeconds {
            items.append(BrewSetting(title: String(localized: "Target time"),
                                     value: BrewSetting.duration(target), icon: "target"))
        }

        return items + BrewSetting.all(for: brew)
    }

    @ViewBuilder
    private var controls: some View {
        switch brew.status {
        case .draft:
            Button { session?.start() } label: {
                Text("Start").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("timer.start")
        case .inProgress:
            HStack(spacing: 12) {
                if session?.isPaused == true {
                    Button { session?.resume() } label: {
                        Text("Resume").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("timer.resume")
                } else {
                    Button { session?.pause() } label: {
                        Text("Pause").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("timer.pause")
                }

                if session?.isPaused == true {
                    finishButton.buttonStyle(.bordered)
                } else {
                    finishButton.buttonStyle(.borderedProminent)
                }
            }
        case .completed:
            EmptyView()
        }
    }

    private var finishButton: some View {
        Button {
            if session?.finish() == true { onFinished(brew) }
        } label: {
            Text("Finish").frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("timer.finish")
    }
}
