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
import MijickPopups

//MARK: - SearchView

struct SearchView: View {
    
    //MARK: - OnDone
    
    var onDone: () -> Void
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    
    //MARK: - Dependencies
    
    @StateObject var searchViewModel: SearchViewModel
    
    //MARK: - Properties
    
    @State var backAnimation = false
    @State var progress: CGFloat = 0.0
    @FocusState var isFocused: Bool
    
    //MARK: - Initializers
    
    init(searchMode: SearchMode = .Territories, onDone: @escaping() -> Void) {
        let searchViewModel = SearchViewModel(mode: searchMode)
        self._searchViewModel = StateObject(wrappedValue: searchViewModel)
        self.onDone = onDone
       
    }
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
                VStack {
                    
                    ScrollView {
                        LazyVStack {
                            switch searchViewModel.searchState {
                            case .Idle:
                                VStack {
                                    if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                        LottieView(animation: .named("searchquiet"))
                                            .playing(loopMode: .loop)
                                            .resizable()
                                            .frame(width: 250, height: 250)
                                    } else {
                                        LottieView(animation: .named("searchquiet"))
                                            .playing(loopMode: .loop)
                                            .resizable()
                                            .frame(width: 350, height: 350)
                                    }
                                    if searchViewModel.searchMode == .Territories {
                                        Text("Search for a Territory, Address, House, Visit")
                                            .font(.title)
                                            .fontWeight(.heavy)
                                            .foregroundColor(.secondaryLabel)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, -50)
                                    } else {
                                        Text("Search for a Phone Territory, Number, Call")
                                            .font(.title)
                                            .fontWeight(.heavy)
                                            .foregroundColor(.secondaryLabel)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, -50)
                                    }
                                    
                                }
                            case .Searching:
                                LazyVStack {
                                    
                                    if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                        LottieView(animation: .named("search"))
                                            .playing(loopMode: .loop)
                                            .resizable()
                                            .frame(width: 250, height: 250)
                                    } else {
                                        LottieView(animation: .named("search"))
                                            .playing(loopMode: .loop)
                                            .resizable()
                                            .frame(width: 350, height: 350)
                                    }
                                    Text("Searching...")
                                        .font(.title)
                                        .fontWeight(.heavy)
                                        .foregroundColor(.secondaryLabel)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, -50)
                                }
                            case .Done:
                                if searchViewModel.searchResults.isEmpty {
                                    LazyVStack {
                                        if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                            LottieView(animation: .named("noresults"))
                                                .playing(loopMode: .loop)
                                                .resizable()
                                                .frame(width: 250, height: 250)
                                        } else {
                                            LottieView(animation: .named("noresults"))
                                                .playing(loopMode: .loop)
                                                .resizable()
                                                .frame(width: 350, height: 350)
                                        }
                                        Text("No results found")
                                            .font(.title)
                                            .fontWeight(.heavy)
                                            .foregroundColor(.secondaryLabel)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, -50)
                                    }
                                } else {
                                    LazyVGrid(columns: [GridItem(.flexible())]) {
                                        ForEach(SearchResultType.allCases, id: \.id) { type in
                                            if searchViewModel.searchResults.contains(where: { $0.type == type }) {
                                                Section(header: Text(type.rawValue).fontWeight(.heavy).font(.title3)) {
                                                    ForEach(searchViewModel.searchResults.filter { $0.type == type }, id: \.id) { data in
                                                        MySearchResultItem(data: data, mainWindowSize: proxy.size)
                                                    }
                                                }
                                            }
                                        }.modifier(ScrollTransitionModifier())
                                    }.animation(.spring(), value: searchViewModel.searchResults)
                                }
                            }
                        }.animation(.easeInOut(duration: 0.5), value: searchViewModel.searchState).padding()
                    }.navigationTransition(.fade(.cross)).scrollIndicators(.never).id(searchViewModel.scrollViewID)
                        .scrollDismissesKeyboard(.never)
                        
                }
                .animation(.easeInOut(duration: 0.5), value: searchViewModel.scrollViewID)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        HStack {
                            Button("", action: {withAnimation { backAnimation.toggle() };
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    
                                    presentationMode.wrappedValue.dismiss()
                                    onDone()
                                }
                            })
                            .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $progress, animation: $backAnimation))
                            
                            SearchBar(searchText: $searchViewModel.searchQuery, isFocused: $isFocused)
                                .padding(.horizontal)
                                .frame(minWidth: proxy.size.width * 0.80)
                        }
                    }
                }
                .navigationBarBackButtonHidden()
        }
    }
}

//MARK: - MySearchResultItem

struct MySearchResultItem: View {
    var data: MySearchResult
    var mainWindowSize: CGSize
    @State var index = 0
    
    init(data: MySearchResult, mainWindowSize: CGSize) {
        self.data = data
        self.mainWindowSize = mainWindowSize
    }
    
    var body: some View {
        LazyVStack {
            switch data.type {
            case .Territory:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(TerritoryView(territoryIdToScrollTo: data.territory!.id))) {
                    CellView(territory: data.territory!, houseQuantity: 0, mainWindowSize: mainWindowSize)
                }.onTapHaptic(.lightImpact)
            case .Address:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(TerritoryAddressView(territory: data.territory!, territoryAddressIdToScrollTo: data.address!.id))) {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(AddressData(id: UUID(), address: data.address!, houseQuantity: 0, accessLevel: .User).address.address)")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .hSpacing(.leading)
                            Text("Doors: \(AddressData(id: UUID(), address: data.address!, houseQuantity: 0, accessLevel: .User).houseQuantity)")
                                .font(.body)
                                .lineLimit(5)
                                .foregroundColor(.secondaryLabel)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .hSpacing(.leading)
                        }
                        .frame(maxWidth: mainWindowSize.width * 0.90)
                    }
                    .hSpacing(.leading)
                    //.id(territory.id)
                    .padding(10)
                    .frame(minWidth: mainWindowSize.width * 0.98)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }.onTapHaptic(.lightImpact)
            case .House:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(HousesView(address: data.address!, houseIdToScrollTo: data.house!.id))) {
                    
                    HouseCell(house: HouseData(id: UUID(), house: data.house!, accessLevel: AuthorizationLevelManager().getAccessLevel(model:  data.house!) ?? .User), mainWindowSize: mainWindowSize)
                }.onTapHaptic(.lightImpact)
            case .Visit:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(VisitsView(house: data.house!, visitIdToScrollTo: data.visit!.id))) {
                    VisitCell(visit: VisitData(id: UUID(), visit: data.visit!, accessLevel: AuthorizationLevelManager().getAccessLevel(model:  data.visit!) ?? .User), mainWindowSize: mainWindowSize)
                }.onTapHaptic(.lightImpact)
            case .PhoneTerritory:
                Text(buildFoundPath(phoneTerritory: data.phoneTerritory, phoneNumber: data.number)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(PhoneTerritoriesScreen(phoneTerritoryToScrollTo: data.phoneTerritory!.id))) {
                    PhoneTerritoryCellView(territory: data.phoneTerritory!, numbers: 0, mainWindowSize: mainWindowSize)
                }.onTapHaptic(.lightImpact)
            case .Number:
                Text(buildFoundPath(phoneTerritory: data.phoneTerritory, phoneNumber: data.number)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(PhoneNumbersView(territory: data.phoneTerritory!, phoneNumberToScrollTo: data.number!.id))) {
                    PhoneNumberCell(numbersData: PhoneNumbersData(id: UUID(), phoneNumber: data.number!), mainWindowSize: mainWindowSize)
                }.onTapHaptic(.lightImpact)
            case .Call:
                Text(buildFoundPath(phoneTerritory: data.phoneTerritory, phoneNumber: data.number)).hSpacing(.leading).bold()
                NavigationLink(destination: NavigationLazyView(CallsView(phoneNumber: data.number!, callToScrollTo: data.call!.id))) {
                    CallCell(call: PhoneCallData(id: UUID(), phoneCall: data.call!, accessLevel: AuthorizationLevelManager().getAccessLevel(model:  data.call!) ?? .User))
                }.onTapHaptic(.lightImpact)
            }
        }
    }
    
    public func buildPath(territory: Territory?, address: TerritoryAddress?, house: House?) -> String {
        let territoryString = "Territory \(territory?.number ?? 0)"
        let addressString: String? = {
            guard let address = address else { return nil }
            return "Address: \(address.address)"
        }()

        let houseString: String? = {
            guard let house = house else { return nil }
            return "House: \(house.number)"
        }()
        
        var finalString = territoryString

        if let addressString = addressString {
            finalString += " → \(addressString)"
        }

        if let houseString = houseString {
            finalString += " → \(houseString)"
        }

        return finalString
    }
    
    private func buildFoundPath(phoneTerritory: PhoneTerritory?, phoneNumber: PhoneNumber?) -> String {
        var territoryString = String.localizedStringWithFormat("Territory: \(phoneTerritory?.number ?? 0)")

        let numberString: String? = {
            guard let phoneNumber = phoneNumber else { return nil }
            return "Number: \(phoneNumber.number.formatPhoneNumber())"
        }()

        if let numberString = numberString {
            territoryString += " → \(numberString)"
        }

        return territoryString
    }

}
