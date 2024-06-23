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
import MijickPopupView


struct SearchView: View {
    @StateObject var searchViewModel: SearchViewModel
    
    @State var backAnimation = false
    @State var progress: CGFloat = 0.0
    
    init(searchMode: SearchMode = .Territories) {
        let searchViewModel = SearchViewModel(mode: searchMode)
        self._searchViewModel = StateObject(wrappedValue: searchViewModel)
    }
    
    @State var isFocused = true
    
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack {
                    
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
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, -50)
                                } else {
                                    Text("Search for a Phone Territory, Number, Call")
                                        .font(.title)
                                        .fontWeight(.heavy)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, -50)
                                }
                                
                            }
                            case .Searching:
                            VStack {
                                
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
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, -50)
                            }
                            case .Done:
                            if searchViewModel.searchResults.isEmpty {
                                VStack {
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
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, -50)
                                }
                            } else {
                                LazyVStack {
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
                    }.animation(.easeInOut(duration: 0.5), value: searchViewModel.searchState)
                        .optionalViewModifier { content in
                            if #available(iOS 17.0, *) {
                                content
                                    .searchable(text: $searchViewModel.searchQuery, isPresented: $isFocused, placement: .navigationBarDrawer(displayMode: .always))
                            } else {
                                content
                                    .searchable(text: $searchViewModel.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
                            }
                            
                        }
                        
                }
                .padding()
            }.navigationTransition(.zoom.combined(with: .fade(.in))).scrollIndicators(.never)
                .scrollDismissesKeyboard(.never)
                .toolbar{
                    ToolbarItemGroup(placement: .keyboard){
                        Spacer()
                        Button("Done"){
                            DispatchQueue.main.async {
                                hideKeyboard()
                            }
                        }.foregroundColor(.primary)
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        HStack {
                            Button("", action: {withAnimation { backAnimation.toggle() };
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }).keyboardShortcut(.delete, modifiers: .command)
                            .buttonStyle(CircleButtonStyle(imageName: "arrow.backward", background: .white.opacity(0), width: 40, height: 40, progress: $progress, animation: $backAnimation))
                        }
                    }
                }
                .navigationBarBackButtonHidden()
        }
    }
}

struct MySearchResultItem: View {
    var data: MySearchResult
    var mainWindowSize: CGSize
    @ObservedObject var houseViewModel: HousesViewModel {
        didSet {
            houseViewModel.getHouses()
        }
    }
    @State var index = 0
    
    init(data: MySearchResult, mainWindowSize: CGSize) {
        self.data = data
        self.mainWindowSize = mainWindowSize
        if data.house != nil {
            let houseViewModel = HousesViewModel(territoryAddress: data.address!)
            
            
            self._houseViewModel = ObservedObject(initialValue: houseViewModel)
            
            
        } else {
            let houseViewModel = HousesViewModel(territoryAddress: TerritoryAddressModel(id: "", territory: "", address: "", created_at: "", updated_at: ""))
            houseViewModel.getHouses()
            self._houseViewModel = ObservedObject(initialValue: houseViewModel)
        }
    }
    
    var body: some View {
        VStack {
            switch data.type {
            case .Territory:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(TerritoryView(territoryIdToScrollTo: data.territory!.id).implementPopupView()).implementPopupView()) {
                    CellView(territory: data.territory!, houseQuantity: 0, mainWindowSize: mainWindowSize)
                }.onTapHaptic(.lightImpact)
            case .Address:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(TerritoryAddressView(territory: data.territory!, territoryAddressIdToScrollTo: data.address!.id).implementPopupView()).implementPopupView()) {
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
                                .foregroundColor(.secondary)
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
                }.onTapHaptic(.lightImpact)
            case .House:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(HousesView(address: data.address!, houseIdToScrollTo: data.house!.id).implementPopupView()).implementPopupView()) {
                    
                    HouseCell(house: HouseData(id: UUID(), house: data.house!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: HouseObject().createHouseObject(from: data.house!)) ?? .User), mainWindowSize: mainWindowSize).id(data.house!.id)
                }.onTapHaptic(.lightImpact)
            case .Visit:
                Text(buildPath(territory: data.territory, address: data.address, house: data.house)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(VisitsView(house: data.house!, visitIdToScrollTo: data.visit!.id)).implementPopupView()) {
                    VisitCell(visit: VisitData(id: UUID(), visit: data.visit!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: VisitObject().createVisitObject(from: data.visit!)) ?? .User))
                }.onTapHaptic(.lightImpact)
            case .PhoneTerritory:
                Text(buildFoundPath(phoneTerritory: data.phoneTerritory, phoneNumber: data.number)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(PhoneTerritoriesScreen(phoneTerritoryToScrollTo: data.phoneTerritory!.id).implementPopupView()).implementPopupView()) {
                    PhoneTerritoryCellView(territory: data.phoneTerritory!, numbers: 0, mainWindowSize: mainWindowSize)
                }.onTapHaptic(.lightImpact)
            case .Number:
                Text(buildFoundPath(phoneTerritory: data.phoneTerritory, phoneNumber: data.number)).hSpacing(.leading).font(.headline).fontWeight(.heavy)
                NavigationLink(destination: NavigationLazyView(PhoneNumbersView(territory: data.phoneTerritory!, phoneNumberToScrollTo: data.number!.id).implementPopupView()).implementPopupView()) {
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
                                .foregroundColor(.secondary)
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
                }.onTapHaptic(.lightImpact)
            case .Call:
                Text(buildFoundPath(phoneTerritory: data.phoneTerritory, phoneNumber: data.number)).hSpacing(.leading).bold()
                NavigationLink(destination: NavigationLazyView(CallsView(phoneNumber: data.number!, callToScrollTo: data.call!.id).implementPopupView()).implementPopupView()) {
                    CallCell(call: PhoneCallData(id: UUID(), phoneCall: data.call!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: PhoneCallObject().createTerritoryObject(from: data.call!)) ?? .User))
                }.onTapHaptic(.lightImpact)
            }
        }
    }
    
    func buildPath(territory: TerritoryModel?, address: TerritoryAddressModel?, house: HouseModel?) -> String {
        var territoryString = "Territory \(territory?.number ?? 0)"
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
    
    private func buildFoundPath(phoneTerritory: PhoneTerritoryModel?, phoneNumber: PhoneNumberModel?) -> String {
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
