//
//  AddressMapView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 11/27/24.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Address Location Model

struct AddressLocation: Identifiable {
    let id: String
    let address: TerritoryAddress
    let coordinate: CLLocationCoordinate2D
    let houses: [House]
    
    var title: String {
        address.address
    }
}

// MARK: - Geocoding Service

@MainActor
class GeocodingService: ObservableObject {
    static let shared = GeocodingService()
    
    private let geocoder = CLGeocoder()
    private var cache: [String: CLLocationCoordinate2D] = [:]
    
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        // Check cache first
        if let cached = cache[address] {
            return cached
        }
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let location = placemarks.first?.location?.coordinate {
                cache[address] = location
                return location
            }
        } catch {
            print("Geocoding error for \(address): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func geocodeAddresses(_ addresses: [TerritoryAddress], houses: [String: [House]]) async -> [AddressLocation] {
        var locations: [AddressLocation] = []
        
        for address in addresses {
            if let coordinate = await geocodeAddress(address.address) {
                let addressHouses = houses[address.id] ?? []
                locations.append(AddressLocation(
                    id: address.id,
                    address: address,
                    coordinate: coordinate,
                    houses: addressHouses
                ))
            }
        }
        
        return locations
    }
    
    /// Check if an address looks like a full address (not just a house number)
    func isFullAddress(_ address: String) -> Bool {
        // A full address typically contains street names, numbers, etc.
        // Simple heuristic: check if it has at least a number and some letters with spaces
        let hasNumber = address.contains(where: { $0.isNumber })
        let hasLetters = address.contains(where: { $0.isLetter })
        let hasSpaces = address.contains(" ")
        let isLongEnough = address.count > 5
        
        return hasNumber && hasLetters && hasSpaces && isLongEnough
    }
}

// MARK: - Address Map View

struct AddressMapView: View {
    let territory: Territory
    let addresses: [AddressData]
    var onSelectAddress: ((TerritoryAddress, House?) -> Void)?
    
    @StateObject private var geocodingService = GeocodingService.shared
    @State private var addressLocations: [AddressLocation] = []
    @State private var selectedLocation: AddressLocation?
    @State private var isLoading = true
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var showCallout = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if addressLocations.isEmpty {
                noMapDataView
            } else {
                mapContent
            }
        }
        .task {
            await loadAddressLocations()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading Map...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - No Map Data View
    
    private var noMapDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Map Not Available")
                .font(.headline)
                .foregroundColor(.primary)
            Text("Addresses could not be located on the map")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - Map Content
    
    private var mapContent: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapCameraPosition, selection: $selectedLocation) {
                ForEach(addressLocations) { location in
                    Annotation(location.title, coordinate: location.coordinate, anchor: .bottom) {
                        AddressMapPin(
                            isSelected: selectedLocation?.id == location.id,
                            houseCount: location.houses.count
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedLocation?.id == location.id {
                                    selectedLocation = nil
                                } else {
                                    selectedLocation = location
                                }
                            }
                        }
                    }
                    .tag(location)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            
            // Callout overlay
            if let selected = selectedLocation {
                AddressCalloutView(
                    location: selected,
                    onGoToAddress: {
                        // Navigate to the first house or the address itself
                        if let firstHouse = selected.houses.first {
                            onSelectAddress?(selected.address, firstHouse)
                        } else {
                            onSelectAddress?(selected.address, nil)
                        }
                    },
                    onGetDirections: {
                        openDirections(to: selected)
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLocation = nil
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Load Address Locations
    
    private func loadAddressLocations() async {
        isLoading = true
        
        // Filter addresses that look like full addresses
        let fullAddresses = addresses.filter { geocodingService.isFullAddress($0.address.address) }
        
        if fullAddresses.isEmpty {
            isLoading = false
            return
        }
        
        // Create houses dictionary
        var housesDict: [String: [House]] = [:]
        // Note: We'd need to fetch houses for each address - for now using empty
        // This would need to be passed in or fetched
        
        let locations = await geocodingService.geocodeAddresses(
            fullAddresses.map { $0.address },
            houses: housesDict
        )
        
        await MainActor.run {
            addressLocations = locations
            isLoading = false
            
            // Set initial camera position to show all pins
            if let firstLocation = locations.first {
                if locations.count == 1 {
                    mapCameraPosition = .region(MKCoordinateRegion(
                        center: firstLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                } else {
                    // Calculate region that fits all pins
                    let coordinates = locations.map { $0.coordinate }
                    let region = regionThatFits(coordinates: coordinates)
                    mapCameraPosition = .region(region)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func regionThatFits(coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5 + 0.005,
            longitudeDelta: (maxLon - minLon) * 1.5 + 0.005
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func openDirections(to location: AddressLocation) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        destination.name = location.title
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Address Map Pin

struct AddressMapPin: View {
    let isSelected: Bool
    let houseCount: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Pin shape
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .teal]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                .shadow(color: .black.opacity(0.3), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            
            // House icon or count
            if houseCount > 0 {
                Text("\(houseCount)")
                    .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "house.fill")
                    .font(.system(size: isSelected ? 20 : 16))
                    .foregroundColor(.white)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Address Callout View

struct AddressCalloutView: View {
    let location: AddressLocation
    var onGoToAddress: () -> Void
    var onGetDirections: () -> Void
    var onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with address and dismiss
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if location.houses.count > 0 {
                        Text("\(location.houses.count) door\(location.houses.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Go to Address button
                Button(action: onGoToAddress) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                        Text("View Houses")
                            .font(.subheadline)
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
                
                // Directions button
                Button(action: onGetDirections) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.title3)
                        Text("Directions")
                            .font(.subheadline)
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
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Preview

#Preview {
    AddressMapView(
        territory: Territory(id: "1", congregation: "1", number: 1, description: "Test Territory", image: ""),
        addresses: []
    )
}

