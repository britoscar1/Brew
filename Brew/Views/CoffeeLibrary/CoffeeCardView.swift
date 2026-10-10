//
//  CoffeeCardView.swift
//  Brew
//
//  Created by Oscar Artemio Brito Ortiz on 15/09/26.
//

import SwiftUI

struct CoffeeCardView: View {
    let coffee: Coffee

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(coffee.name)
                    .font(.headline)

                if let roaster = coffee.roaster {
                    Text(roaster)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(coffee.origin)
                    }

                    Text("•")

                    Text(coffee.roastLevel?.title ?? String(localized: "Unknown roast"))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image("CoffeeBeansDuotone")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(Color("CoffeeCrema").opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color("CoffeeTint").opacity(0.12))
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}
