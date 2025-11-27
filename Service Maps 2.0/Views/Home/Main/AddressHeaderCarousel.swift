//
//  AddressHeaderCarousel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 11/27/24.
//

import SwiftUI
import NukeUI

// MARK: - Header Card Type

enum AddressHeaderCardType: Int, CaseIterable, Identifiable {
    case image = 0
    case map = 1
    
    var id: Int { rawValue }
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .map: return "map"
        }
    }
}

// MARK: - Address Header Carousel

struct AddressHeaderCarousel: View {
    let territory: Territory
    let addresses: [AddressData]
    let progress: CGFloat
    let mainWindowSize: CGSize
    let headerInfo: TerritoryHeaderInfo
    var onImageTap: () -> Void
    var onSelectAddress: ((TerritoryAddress, House?) -> Void)?
    
    @State private var currentPage: AddressHeaderCardType = .image
    @State private var hasFullAddresses: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Carousel content
                TabView(selection: $currentPage) {
                    // Image Card
                    imageCard
                        .tag(AddressHeaderCardType.image)
                    
                    // Map Card (only if we have full addresses)
                    if hasFullAddresses {
                        mapCard
                            .tag(AddressHeaderCardType.map)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 350)
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                
                // Bottom overlay with header info and page indicator
                VStack(spacing: 0) {
                    // Page indicator (only show if map is available)
                    if hasFullAddresses {
                        pageIndicator
                            .padding(.bottom, 8)
                    }
                    
                    // Small header info
                    smallHeader(headerInfo, progress: progress)
                }
            }
        }
        .frame(width: mainWindowSize.width, height: 350)
        .animation(.easeInOut, value: progress)
        .onAppear {
            checkForFullAddresses()
        }
        .onChange(of: addresses) { _ in
            checkForFullAddresses()
        }
    }
    
    // MARK: - Image Card
    
    private var imageCard: some View {
        LazyImage(url: URL(string: territory.getImageURL())) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: mainWindowSize.width, height: 350)
                    .clipped()
                    .onTapGesture {
                        if !territory.getImageURL().isEmpty {
                            HapticManager.shared.trigger(.lightImpact)
                            onImageTap()
                        }
                    }
            } else if state.isLoading {
                ZStack {
                    Color(UIColor.secondarySystemBackground)
                    ProgressView()
                }
                .frame(height: 350)
            } else {
                ZStack {
                    Color(UIColor.secondarySystemBackground)
                    Image("mapImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: mainWindowSize.width, height: 100)
                }
                .frame(height: 350)
            }
        }
    }
    
    // MARK: - Map Card
    
    private var mapCard: some View {
        AddressMapView(
            territory: territory,
            addresses: addresses,
            onSelectAddress: onSelectAddress
        )
        .frame(height: 350)
        .allowsHitTesting(true)
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(AddressHeaderCardType.allCases) { type in
                if type == .map && !hasFullAddresses {
                    EmptyView()
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            currentPage = type
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption2)
                            if currentPage == type {
                                Text(type == .image ? "Photo" : "Map")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(currentPage == type ? .white : .white.opacity(0.7))
                        .padding(.horizontal, currentPage == type ? 12 : 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(currentPage == type 
                                      ? LinearGradient(gradient: Gradient(colors: [.blue, .teal]), startPoint: .leading, endPoint: .trailing)
                                      : LinearGradient(gradient: Gradient(colors: [.white.opacity(0.2), .white.opacity(0.2)]), startPoint: .leading, endPoint: .trailing)
                                )
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Small Header
    
    private func smallHeader(_ info: TerritoryHeaderInfo, progress: CGFloat) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("№")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text("\(info.number)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            if info.imageURL != "", !(progress < 0.98) {
                LazyImage(url: URL(string: info.imageURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Color.gray.opacity(0.2)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(info.description)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(AnyShapeStyle(.ultraThickMaterial))
                .background(
                    (progress < 0.98 && colorScheme == .light) ?
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 0.5)
                    : nil
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            progress < 0.98
                            ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.05))
                            : Color.clear,
                            lineWidth: 0.6
                        )
                )
                .shadow(
                    color: .black.opacity(progress < 0.98 ? (colorScheme == .dark ? 0.1 : 0.06) : 0),
                    radius: progress < 0.98 ? 6 : 0,
                    x: 0,
                    y: progress < 0.98 ? 3 : 0
                )
                .cornerRadius((progress < 0.98) ? 20 : 0, corners: [.topLeft, .topRight])
                .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
        )
        .animation(.easeInOut(duration: 0.2), value: progress)
    }
    
    // MARK: - Check for Full Addresses
    
    private func checkForFullAddresses() {
        let geocodingService = GeocodingService.shared
        hasFullAddresses = addresses.contains { geocodingService.isFullAddress($0.address.address) }
    }
}

// MARK: - Preview

#Preview {
    AddressHeaderCarousel(
        territory: Territory(id: "1", congregation: "1", number: 1, description: "Test Territory", image: ""),
        addresses: [],
        progress: 0.5,
        mainWindowSize: CGSize(width: 390, height: 844),
        headerInfo: TerritoryHeaderInfo(number: 1, description: "Test", imageURL: ""),
        onImageTap: {}
    )
}

