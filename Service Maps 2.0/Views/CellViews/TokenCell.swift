//
//  TokenCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/9/24.
//

import SwiftUI

//MARK: - Token Cell

@MainActor
struct TokenCell: View {
    @ObservedObject var dataStore = StorageManager.shared
    var keyData: KeyData
    var ipad: Bool = false

    @Environment(\.mainWindowSize) var mainWindowSize

    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(keyData.key.name)
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            Text(keyData.key.user == dataStore.userEmail || keyData.key.moderator ? "Level: Servant" : "Level: Publisher")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Territories: \(processData(key: keyData))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(keyData.key.user == dataStore.userEmail ? dataStore.userName ?? "" : keyData.key.user ?? keyData.key.owner)
                        .font(.subheadline)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondaryLabel)
                }
            }
        }
        .padding()
        .frame(minWidth: ipad ? (mainWindowSize.width / 2) * 0.90 : mainWindowSize.width * 0.90)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .optionalViewModifier { content in
            if isIpad {
                content.frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }

    private func processData(key: KeyData) -> String {
        key.territories.sorted { $0.number < $1.number }
            .map { String($0.number) }
            .joined(separator: ", ")
    }
}

//MARK: - User Token Cell

struct UserTokenCell: View {
    @ObservedObject var dataStore = StorageManager.shared
    var userKeyData: UserToken

    @Environment(\.mainWindowSize) var mainWindowSize

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.blue)

            Text(userKeyData.name)
                .font(.title3)
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
