//
//  TasteScale.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import SwiftUI

struct TasteScale: View {
    enum Style {
        case position
        case rating
    }

    let title: LocalizedStringKey
    let labels: [LocalizedStringKey]
    let style: Style
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(labels[value - 1])
                    .font(.subheadline)
                    .foregroundStyle(Color("CoffeeTint"))
            }

            HStack(spacing: 6) {
                ForEach(1...labels.count, id: \.self) { step in
                    Button {
                        withAnimation(.snappy(duration: 0.18)) { value = step }
                    } label: {
                        Capsule()
                            .fill(Color("CoffeeTint").opacity(fill(for: step)))
                            .frame(height: step == value ? 14 : 8)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 14)

            HStack {
                Text(labels[0])
                Spacer()
                Text(labels[labels.count - 1])
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(labels[value - 1]))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 1, labels.count)
            case .decrement: value = max(value - 1, 1)
            @unknown default: break
            }
        }
    }

    private func fill(for step: Int) -> Double {
        switch style {
        case .position: step == value ? 1 : 0.15
        case .rating: step <= value ? 1 : 0.15
        }
    }
}
