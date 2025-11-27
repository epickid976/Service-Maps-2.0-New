//
//  AddressHeaderCarousel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 11/27/24.
//

import SwiftUI
import NukeUI
import MapKit

// MARK: - Address Header Carousel

struct AddressHeaderCarousel: View {
    let territory: Territory
    let addresses: [AddressData]
    let progress: CGFloat
    let mainWindowSize: CGSize
    var onImageTap: () -> Void
    var onSelectAddress: ((TerritoryAddress) -> Void)?
    
    @State private var currentPage: Int = 0
    @State private var hasFullAddresses: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                // Horizontal paging carousel
                TabView(selection: $currentPage) {
                    // Page 1: Territory Image
                    imageCard
                        .tag(0)
                    
                    // Page 2: Map View (only if there are geocodable addresses)
                    if hasFullAddresses {
                        mapCard
                            .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 350)
                
                // Custom page indicator
                if hasFullAddresses {
                    pageIndicator
                        .padding(.bottom, 90)
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
        ZStack(alignment: .bottom) {
            LazyImage(url: URL(string: territory.getImageURL())) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: mainWindowSize.width, height: 350)
                        .clipped()
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
                            .frame(width: 100, height: 100)
                    }
                    .frame(height: 350)
                }
            }
            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
            .frame(height: 350)
            .onTapGesture {
                onImageTap()
            }
            
            // Territory info overlay at bottom
            territoryInfoOverlay
        }
    }
    
    // MARK: - Map Card
    
    private var mapCard: some View {
        ZStack(alignment: .bottom) {
            AddressMapView(
                territory: territory,
                addresses: addresses,
                onSelectAddress: { address, house in
                    onSelectAddress?(address)
                }
            )
            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
            .frame(height: 350)
            
            // Map info overlay at bottom
            mapInfoOverlay
        }
    }
    
    // MARK: - Territory Info Overlay
    
    private var territoryInfoOverlay: some View {
        HStack(spacing: 16) {
            // Territory number badge
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text("№\(territory.number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(territory.description)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("\(addresses.count) address\(addresses.count == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Swipe hint for map
            if hasFullAddresses {
                HStack(spacing: 4) {
                    Text("Map")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Map Info Overlay
    
    private var mapInfoOverlay: some View {
        HStack(spacing: 16) {
            // Map icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Territory Map")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Tap a pin for options")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Swipe hint for image
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Photo")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<(hasFullAddresses ? 2 : 1), id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Helpers
    
    private func checkForFullAddresses() {
        // Check if any address looks like a full address (not just a house number)
        hasFullAddresses = addresses.contains { addressData in
            GeocodingService.shared.isFullAddress(addressData.address.address)
        }
    }
}

// MARK: - Preview

#Preview {
    AddressHeaderCarousel(
        territory: Territory(id: "1", congregation: "1", number: 1, description: "Test Territory", image: ""),
        addresses: [],
        progress: 0,
        mainWindowSize: CGSize(width: 393, height: 852),
        onImageTap: {}
    )
}

