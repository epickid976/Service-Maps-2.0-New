//
//  HouseCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import SwiftUI
import NukeUI
import Combine

//MARK: - House Cell

struct HouseCell: View {
    @State var revisitView: Bool = false
    @StateObject private var visitViewModel: VisitsViewModel
    @State private var house: HouseData
    @State private var cancellable: AnyCancellable?
    @Environment(\.colorScheme) private var colorScheme

    var mainWindowSize: CGSize

    var isIpad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }

    init(revisitView: Bool = false, house: HouseData, mainWindowSize: CGSize) {
        _visitViewModel = StateObject(wrappedValue: VisitsViewModel(house: house.house, revisitView: revisitView))
        _house = State(initialValue: house)
        self.mainWindowSize = mainWindowSize
        _revisitView = State(initialValue: revisitView)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - House Header
            HStack {
                Text("\(house.house.number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Text(NSLocalizedString(house.visit?.symbol.uppercased() ?? "-", comment: ""))
                    .font(.caption)
                    .fontWeight(.heavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                            {
                                switch house.visit?.symbol.lowercased() {
                                case "nt":
                                    return Color.red.opacity(colorScheme == .dark ? 0.8 : 0.9)
                                case "uk":
                                    return Color.gray.opacity(colorScheme == .dark ? 0.6 : 0.7)
                                default:
                                    return Color.blue.opacity(colorScheme == .dark ? 0.8 : 0.9)
                                }
                            }()
                        )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            // MARK: - Visit Preview
            if let visit = house.visit {
                visitSummary(visit)
            } else {
                noVisitSummary
            }
        }
        .padding()
        .frame(minWidth: mainWindowSize.width * 0.95)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            colorScheme == .dark ?
                                Color.white.opacity(0.2) :
                                Color.black.opacity(0.07),
                            lineWidth: colorScheme == .dark ? 1 : 0.8
                        )
                )
                .shadow(
                    color: colorScheme == .dark ?
                        .black.opacity(0.1) :
                        .black.opacity(0.07),
                    radius: colorScheme == .dark ? 10 : 8,
                    x: 0,
                    y: colorScheme == .dark ? 4 : 3
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
    }

    // MARK: - Visit Block (Nested)
    private func visitSummary(_ visit: Visit) -> some View {
        let date = Date(timeIntervalSince1970: TimeInterval(visit.date / 1000))

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDate(date: date))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()
            }

            Text(visit.notes)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(6)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(visit.user)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(colorScheme == .dark ? 0.1 : 0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - No Visit Block
    private var noVisitSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .foregroundColor(.secondary)

            Text("No notes available.")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Spacer() // Pushes content to the leading side
        }
        .padding(12)
        .frame(maxWidth: .infinity) // Forces the width to fill parent
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(colorScheme == .dark ? 0.1 : 0.15))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Lifecycle
    private func onAppear() {
        visitViewModel.getVisits(revisitView: revisitView)
        cancellable = visitViewModel.latestVisitUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { newVisit in
                if let newVisit, newVisit.house == house.house.id, newVisit != house.visit {
                    house.visit = newVisit
                } else if newVisit == nil {
                    house.visit = nil
                }
            }
    }

    private func onDisappear() {
        cancellable?.cancel()
    }
}
