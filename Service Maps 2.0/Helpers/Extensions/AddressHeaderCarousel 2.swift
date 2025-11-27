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
    var onSelectAddress: ((TerritoryAddress, String?) -> Void)?  // address, houseIdToScrollTo
    @Binding var isFullscreenMap: Bool
    @Binding var fullscreenAddressLocations: [AddressLocation]
    
    @State private var currentPage: Int = 0
    @State private var hasFullAddresses: Bool = false
    @State private var selectedLocation: AddressLocation?
    @State private var addressLocations: [AddressLocation] = []
    @State private var isLoadingMap: Bool = true
    @ObservedObject private var dataStore = StorageManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        territory: Territory,
        addresses: [AddressData],
        progress: CGFloat,
        mainWindowSize: CGSize,
        onImageTap: @escaping () -> Void,
        onSelectAddress: ((TerritoryAddress, String?) -> Void)? = nil,
        isFullscreenMap: Binding<Bool> = .constant(false),
        fullscreenAddressLocations: Binding<[AddressLocation]> = .constant([])
    ) {
        self.territory = territory
        self.addresses = addresses
        self.progress = progress
        self.mainWindowSize = mainWindowSize
        self.onImageTap = onImageTap
        self.onSelectAddress = onSelectAddress
        self._isFullscreenMap = isFullscreenMap
        self._fullscreenAddressLocations = fullscreenAddressLocations
    }
    
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
            }
        }
        .frame(width: mainWindowSize.width, height: 350)
        .animation(.easeInOut, value: progress)
        .task(id: addresses.count) {
            checkForFullAddresses()
            if hasFullAddresses && !addresses.isEmpty {
                await loadAddressLocations()
            }
        }
        .onChange(of: dataStore.synchronized) { synced in
            // Refetch data after sync completes
            if synced && hasFullAddresses && !addresses.isEmpty {
                Task {
                    await loadAddressLocations()
                }
            }
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
        ZStack {
            // Map view
            AddressMapView(
                territory: territory,
                addressLocations: addressLocations,
                isLoading: isLoadingMap,
                selectedLocation: $selectedLocation
            )
            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
            .frame(height: 350)
            
            // Overlay at bottom - shows selected pin info or default map info
            VStack {
                Spacer()
                mapOverlay
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedLocation != nil)
            }
        }
    }
    
    // MARK: - Map Overlay (shows selected pin or default info)
    
    private var mapOverlay: some View {
        VStack(spacing: 8) {
            if let selected = selectedLocation {
                // Selected pin info
                selectedPinOverlay(selected)
            } else {
                // Default map info
                defaultMapOverlay
            }
            
            // Page indicator dots
            pageIndicator
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Selected Pin Overlay
    
    @ViewBuilder
    private func selectedPinOverlay(_ location: AddressLocation) -> some View {
        VStack(spacing: 12) {
            // Header with address info
            HStack(spacing: 12) {
                // Pin badge
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
                    
                    if let firstHouse = location.houses.first {
                        Text(firstHouse.number)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    } else {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !location.houses.isEmpty {
                        Text("Doors: \(location.houseNumbers)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let lastVisit = location.lastVisit {
                        HStack(spacing: 4) {
                            Text(lastVisit.symbol)
                                .font(.caption)
                            Text(formattedDate(lastVisit.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Dismiss button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedLocation = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button {
                    // Pass the first house ID for highlighting/scrolling
                    let houseId = location.houses.first?.id
                    onSelectAddress?(location.address, houseId)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.subheadline)
                        Text("View House")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                
                Button {
                    openDirections(to: location)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.subheadline)
                        Text("Directions")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        colorScheme == .dark
                            ? Color.white.opacity(0.15)
                            : Color.black.opacity(0.08)
                    )
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Default Map Overlay
    
    private var defaultMapOverlay: some View {
        VStack(spacing: 12) {
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
                
                VStack {
                    // Swipe hint for image
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Photo")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    // Fullscreen button
                    Button {
                        fullscreenAddressLocations = addressLocations
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isFullscreenMap = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                            Text("Full Screen")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            colorScheme == .dark
                                ? Color.white.opacity(0.15)
                                : Color.black.opacity(0.08)
                        )
                        .cornerRadius(10)
                    }
                }
            }
            
            
        }
    }
    
    // MARK: - Territory Info Overlay
    
    private var territoryInfoOverlay: some View {
        VStack(spacing: 8) {
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
            
            // Page indicator dots - below the info
            if hasFullAddresses {
                pageIndicator
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
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.primary : Color.primary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func checkForFullAddresses() {
        hasFullAddresses = addresses.contains { addressData in
            GeocodingService.shared.isFullAddress(addressData.address.address)
        }
    }
    
    private func loadAddressLocations() async {
        isLoadingMap = true
        let locations = await GeocodingService.shared.geocodeAddresses(addresses.filter {
            GeocodingService.shared.isFullAddress($0.address.address)
        })
        await MainActor.run {
            addressLocations = locations
            isLoadingMap = false
        }
    }
    
    private func formattedDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func openDirections(to location: AddressLocation) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        destination.name = location.title
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Fullscreen Map View

struct FullscreenMapView: View {
    let territory: Territory
    let addressLocations: [AddressLocation]
    @Binding var isPresented: Bool
    var onSelectAddress: ((TerritoryAddress, String?) -> Void)?
    
    @State private var selectedLocation: AddressLocation?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Full screen map
            AddressMapView(
                territory: territory,
                addressLocations: addressLocations,
                isLoading: false,
                selectedLocation: $selectedLocation
            )
            .ignoresSafeArea()
            
            // Top bar with close button
            VStack {
                HStack {
                    // Close button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // Title
                    Text("Territory \(territory.number)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                // Bottom overlay when pin selected
                if let selected = selectedLocation {
                    fullscreenSelectedOverlay(selected)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedLocation != nil)
                }
            }
        }
        .statusBarHidden(true)
    }
    
    @ViewBuilder
    private func fullscreenSelectedOverlay(_ location: AddressLocation) -> some View {
        VStack(spacing: 12) {
            // Header with address info
            HStack(spacing: 12) {
                // Pin badge
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
                    
                    if let firstHouse = location.houses.first {
                        Text(firstHouse.number)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    } else {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if !location.houses.isEmpty {
                        Text("Doors: \(location.houseNumbers)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastVisit = location.lastVisit {
                        HStack(spacing: 4) {
                            Text(lastVisit.symbol)
                                .font(.caption)
                            Text(formattedDate(lastVisit.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Dismiss button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedLocation = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button {
                    let houseId = location.houses.first?.id
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSelectAddress?(location.address, houseId)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.subheadline)
                        Text("View House")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Button {
                    openDirections(to: location)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.subheadline)
                        Text("Directions")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        colorScheme == .dark
                            ? Color.white.opacity(0.15)
                            : Color.black.opacity(0.08)
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private func formattedDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func openDirections(to location: AddressLocation) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        destination.name = location.title
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
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
