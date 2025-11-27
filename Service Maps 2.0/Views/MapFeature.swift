//
//  MapFeature.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 11/27/24.
//

import SwiftUI
import MapKit
import CoreLocation
import GRDB

// MARK: - Address Location Model

struct AddressLocation: Identifiable, Hashable {
    let id: String
    let address: TerritoryAddress
    let coordinate: CLLocationCoordinate2D
    let houseCount: Int
    let houses: [House]
    let lastVisit: Visit?
    
    var title: String {
        address.address
    }
    
    var houseNumbers: String {
        if houses.isEmpty {
            return "\(houseCount) doors"
        }
        let numbers = houses.prefix(5).map { $0.number }.joined(separator: ", ")
        if houses.count > 5 {
            return "\(numbers)..."
        }
        return numbers
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AddressLocation, rhs: AddressLocation) -> Bool {
        lhs.id == rhs.id
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
    
    func geocodeAddresses(_ addresses: [AddressData]) async -> [AddressLocation] {
        var locations: [AddressLocation] = []
        
        for addressData in addresses {
            if let coordinate = await geocodeAddress(addressData.address.address) {
                // Fetch houses and last visit for this address
                let (houses, lastVisit) = fetchHousesAndLastVisit(for: addressData.address.id)
                
                locations.append(AddressLocation(
                    id: addressData.address.id,
                    address: addressData.address,
                    coordinate: coordinate,
                    houseCount: addressData.houseQuantity,
                    houses: houses,
                    lastVisit: lastVisit
                ))
            }
        }
        
        return locations
    }
    
    private func fetchHousesAndLastVisit(for addressId: String) -> ([House], Visit?) {
        do {
            let houses = try GRDBManager.shared.dbPool.read { db in
                try House.filter(Column("territory_address") == addressId).fetchAll(db)
            }
            
            // Get the most recent visit across all houses
            var lastVisit: Visit? = nil
            for house in houses {
                if let visit = try GRDBManager.shared.dbPool.read({ db in
                    try Visit.filter(Column("house") == house.id)
                        .order(Column("date").desc)
                        .fetchOne(db)
                }) {
                    if lastVisit == nil || visit.date > lastVisit!.date {
                        lastVisit = visit
                    }
                }
            }
            
            return (houses, lastVisit)
        } catch {
            print("Error fetching houses: \(error)")
            return ([], nil)
        }
    }
    
    /// Check if an address looks like a full address (not just a house number)
    func isFullAddress(_ address: String) -> Bool {
        let hasNumber = address.contains(where: { $0.isNumber })
        let hasLetters = address.contains(where: { $0.isLetter })
        let hasSpaces = address.contains(" ")
        let isLongEnough = address.count > 5
        
        return hasNumber && hasLetters && hasSpaces && isLongEnough
    }
}

// MARK: - Address Map View (Simplified - overlay handled by parent)

struct AddressMapView: View {
    let territory: Territory
    let addressLocations: [AddressLocation]
    let isLoading: Bool
    @Binding var selectedLocation: AddressLocation?
    var onSelectAddress: ((TerritoryAddress, House?) -> Void)?
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var hasSetInitialRegion = false
    
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
        .onChange(of: addressLocations) { newLocations in
            if !newLocations.isEmpty && !hasSetInitialRegion {
                setInitialRegion(for: newLocations)
                hasSetInitialRegion = true
            }
        }
        .onAppear {
            if !addressLocations.isEmpty && !hasSetInitialRegion {
                setInitialRegion(for: addressLocations)
                hasSetInitialRegion = true
            }
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
        Map(coordinateRegion: $mapRegion, annotationItems: addressLocations) { location in
            MapAnnotation(coordinate: location.coordinate, anchorPoint: CGPoint(x: 0.5, y: 1.0)) {
                AddressMapPin(
                    isSelected: selectedLocation?.id == location.id,
                    location: location
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
        }
    }
    
    // MARK: - Helpers
    
    private func setInitialRegion(for locations: [AddressLocation]) {
        guard let firstLocation = locations.first else { return }
        
        if locations.count == 1 {
            mapRegion = MKCoordinateRegion(
                center: firstLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        } else {
            let coordinates = locations.map { $0.coordinate }
            mapRegion = regionThatFits(coordinates: coordinates)
        }
    }
    
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
}

// MARK: - Address Map Pin

struct AddressMapPin: View {
    let isSelected: Bool
    let location: AddressLocation
    
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
            
            // Show first house number or count
            if let firstHouse = location.houses.first {
                Text(firstHouse.number)
                    .font(.system(size: isSelected ? 16 : 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else if location.houseCount > 0 {
                Text("\(location.houseCount)")
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

// MARK: - Preview

#Preview {
    AddressMapView(
        territory: Territory(id: "1", congregation: "1", number: 1, description: "Test Territory", image: ""),
        addressLocations: [],
        isLoading: false,
        selectedLocation: .constant(nil)
    )
}
