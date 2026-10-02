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
        VStack(spacing: 28) {
            header

            timer

            details

            Spacer(minLength: 0)

            controls
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("CoffeeCanvas"))
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
            }

            if session?.isPaused == true {
                Text("Paused")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
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
        case .inProgress:
            HStack(spacing: 12) {
                if session?.isPaused == true {
                    Button { session?.resume() } label: {
                        Text("Resume").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button { session?.pause() } label: {
                        Text("Pause").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
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
    }
}
