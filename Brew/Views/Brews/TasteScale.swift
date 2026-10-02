//
//  TasteScale.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 24/09/26.
//

import SwiftUI

struct TasteScale: View {
    private enum Source {
        case editable(Binding<Int>)
        case fixed(Int)
    }

    let dimension: TasteDimension
    private let source: Source

    init(dimension: TasteDimension, selection: Binding<Int>) {
        self.dimension = dimension
        source = .editable(selection)
    }

    init(dimension: TasteDimension, value: Int) {
        self.dimension = dimension
        source = .fixed(value)
    }

    @ViewBuilder
    var body: some View {
        if let selection {
            scale.accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: selection.wrappedValue = min(value + 1, labels.count)
                case .decrement: selection.wrappedValue = max(value - 1, 1)
                @unknown default: break
                }
            }
        } else {
            scale
        }
    }

    private var scale: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dimension.title)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(labels[value - 1])
                    .font(.subheadline)
                    .foregroundStyle(Color("CoffeeTint"))
            }

            HStack(spacing: 6) {
                ForEach(1...labels.count, id: \.self) { step in
                    if let selection {
                        Button {
                            withAnimation(.snappy(duration: 0.18)) { selection.wrappedValue = step }
                        } label: {
                            capsule(for: step)
                        }
                        .buttonStyle(.plain)
                    } else {
                        capsule(for: step)
                    }
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
        .accessibilityLabel(Text(dimension.title))
        .accessibilityValue(Text(labels[value - 1]))
    }

    private func capsule(for step: Int) -> some View {
        Capsule()
            .fill(Color("CoffeeTint").opacity(fill(for: step)))
            .frame(height: step == value ? 14 : 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }

    private var labels: [LocalizedStringKey] {
        dimension.labels
    }

    private var selection: Binding<Int>? {
        switch source {
        case let .editable(selection): selection
        case .fixed: nil
        }
    }

    private var value: Int {
        let stored = switch source {
        case let .editable(selection): selection.wrappedValue
        case let .fixed(value): value
        }

        return min(max(stored, 1), labels.count)
    }

    private func fill(for step: Int) -> Double {
        if dimension.isCumulative {
            step <= value ? 1 : 0.15
        } else {
            step == value ? 1 : 0.15
        }
    }
}
