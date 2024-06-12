//
//  SearchView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/11/24.
//

import Foundation
import SwiftUI
import CoreData
import NavigationTransitions
import SwipeActions
import Combine
import UIKit
import Lottie
import AlertKit
import PopupView
import MijickPopupView


struct SearchView: View {
    @StateObject var searchViewModel: SearchViewModel
    
    init(searchMode: SearchMode = .Territories) {
        let searchViewModel = SearchViewModel(mode: searchMode)
        self._searchViewModel = StateObject(wrappedValue: searchViewModel)
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack {
                    SearchBar(searchText: $searchViewModel.searchQuery)
                    
                    LazyVStack {
                        if searchViewModel.searchState == .Searching {
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                LottieView(animation: .named("loading"))
                                    .playing(loopMode: .autoReverse)
                                    .resizable()
                                    .frame(width: 250, height: 250)
                            } else {
                                LottieView(animation: .named("loading"))
                                    .playing(loopMode: .autoReverse)
                                    .resizable()
                                    .frame(width: 350, height: 350)
                            }
                        } else if searchViewModel.searchState == .Done && searchViewModel.searchQuery.isEmpty {
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                LottieView(animation: .named("searchquiet"))
                                    .playing(loopMode: .autoReverse)
                                    .resizable()
                                    .frame(width: 250, height: 250)
                            } else {
                                LottieView(animation: .named("searchquiet"))
                                    .playing(loopMode: .autoReverse)
                                    .resizable()
                                    .frame(width: 350, height: 350)
                            }
                        } else if searchViewModel.isLoaded() {
                            // Display search results
                            ForEach(SearchResultType.allCases, id: \.self) { type in
                                if searchViewModel.searchResults.contains(where: { $0.type == type }) {
                                    Section(header: Text(type.rawValue)) {
                                        ForEach(searchViewModel.searchResults.filter { $0.type == type }, id: \.self.id) { data in
                                            MySearchResultItem(data: data, mainWindowSize: proxy.size)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct MySearchResultItem: View {
    var data: MySearchResult
    var mainWindowSize: CGSize
    
    var body: some View {
        VStack {
            switch data.type {
            case .Territory:
                NavigationLink(destination: TerritoryView()) {
                    CellView(territory: data.territory!, houseQuantity: 0, mainWindowSize: mainWindowSize)
                }
            case .Address:
                NavigationLink(destination: TerritoryAddressView(territory: data.territory!)) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(AddressData(id: ObjectIdentifier(TerritoryAddressObject().createTerritoryAddressObject(from: data.address!)), address: data.address!, houseQuantity: 0, accessLevel: .User).address.address)")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .hSpacing(.leading)
                            Text("Doors: \(AddressData(id: ObjectIdentifier(TerritoryAddressObject().createTerritoryAddressObject(from: data.address!)), address: data.address!, houseQuantity: 0, accessLevel: .User).houseQuantity)")
                                .font(.body)
                                .lineLimit(5)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                        }
                        .frame(maxWidth: mainWindowSize.width * 0.90)
                    }
                    //.id(territory.id)
                    .padding(10)
                    .frame(minWidth: mainWindowSize.width * 0.95)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            case .House:
                NavigationLink(destination: HousesView(address: data.address!)) {
                    HouseCell(house: HouseData(id: UUID(), house: data.house!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: HouseObject().createHouseObject(from: data.house!)) ?? .User), mainWindowSize: mainWindowSize)
                }
            case .Visit:
                NavigationLink(destination: VisitsView(house: data.house!)) {
                    VisitCell(visit: VisitData(id: UUID(), visit: data.visit!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: VisitObject().createVisitObject(from: data.visit!)) ?? .User))
                }
            case .PhoneTerritory:
                NavigationLink(destination: PhoneTerritoriesScreen()) {
                    PhoneTerritoryCellView(territory: data.phoneTerritory!, numbers: 0, mainWindowSize: mainWindowSize)
                }
            case .Number:
                NavigationLink(destination: PhoneNumbersView(territory: data.phoneTerritory!)) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(PhoneNumbersData(id: UUID(), phoneNumber: data.number!, phoneCall: nil).phoneNumber.number.formatPhoneNumber())")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .hSpacing(.leading)
                            Text("House: \(PhoneNumbersData(id: UUID(), phoneNumber: data.number!, phoneCall: nil).phoneNumber.house ?? "N/A")")
                                .font(.body)
                                .lineLimit(5)
                                .foregroundColor(.primary)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                            VStack {
                                HStack {
                                    if let call = PhoneNumbersData(id: UUID(), phoneNumber: data.number!, phoneCall: nil).phoneCall  {
                                            Text("Note: \(call.notes)")
                                                .font(.headline)
                                                .lineLimit(2)
                                                .foregroundColor(.primary)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .hSpacing(.leading)
                                        
                                    } else {
                                        Text("Note: N/A")
                                            .font(.headline)
                                            .lineLimit(2)
                                            .foregroundColor(.primary)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.leading)
                                            .hSpacing(.leading)
                                        
                                    }
                                }
                            }
                            .frame(maxWidth: mainWindowSize.width * 0.95, maxHeight: 75)
                        }
                        .frame(maxWidth: mainWindowSize.width * 0.90)
                    }
                    //.id(territory.id)
                    .padding(10)
                    .frame(minWidth: mainWindowSize.width * 0.95)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            case .Call:
                NavigationLink(destination: CallsView(phoneNumber: data.number!)) {
                    CallCell(call: PhoneCallData(id: UUID(), phoneCall: data.call!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: PhoneCallObject().createTerritoryObject(from: data.call!)) ?? .User))
                }
            }
        }
    }
}
