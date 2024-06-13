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
    
    @State var backAnimation = false
    @State var progress: CGFloat = 0.0
    
    init(searchMode: SearchMode = .Territories) {
        let searchViewModel = SearchViewModel(mode: searchMode)
        self._searchViewModel = StateObject(wrappedValue: searchViewModel)
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack {
                    SearchBar(searchText: $searchViewModel.searchQuery)
                    
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
                                    }
                                }.animation(.spring(), value: searchViewModel.searchResults)
                            }
                        }
                    }.animation(.easeInOut(duration: 0.5), value: searchViewModel.searchState)
                }
                .padding()
            }.navigationTransition(.zoom.combined(with: .fade(.in)))
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
    
    var body: some View {
        VStack {
            switch data.type {
            case .Territory:
                NavigationLink(destination: NavigationLazyView(TerritoryView().implementPopupView()).implementPopupView()) {
                    CellView(territory: data.territory!, houseQuantity: 0, mainWindowSize: mainWindowSize)
                }
            case .Address:
                NavigationLink(destination: NavigationLazyView(TerritoryAddressView(territory: data.territory!).implementPopupView()).implementPopupView()) {
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
                NavigationLink(destination: NavigationLazyView(HousesView(address: data.address!).implementPopupView()).implementPopupView()) {
                    HouseCell(house: HouseData(id: UUID(), house: data.house!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: HouseObject().createHouseObject(from: data.house!)) ?? .User), mainWindowSize: mainWindowSize)
                }
            case .Visit:
                NavigationLink(destination: NavigationLazyView(VisitsView(house: data.house!).implementPopupView()).implementPopupView()) {
                    VisitCell(visit: VisitData(id: UUID(), visit: data.visit!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: VisitObject().createVisitObject(from: data.visit!)) ?? .User))
                }
            case .PhoneTerritory:
                NavigationLink(destination: NavigationLazyView(PhoneTerritoriesScreen().implementPopupView()).implementPopupView()) {
                    PhoneTerritoryCellView(territory: data.phoneTerritory!, numbers: 0, mainWindowSize: mainWindowSize)
                }
            case .Number:
                NavigationLink(destination: NavigationLazyView(PhoneNumbersView(territory: data.phoneTerritory!).implementPopupView()).implementPopupView()) {
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
                NavigationLink(destination: NavigationLazyView(CallsView(phoneNumber: data.number!).implementPopupView()).implementPopupView()) {
                    CallCell(call: PhoneCallData(id: UUID(), phoneCall: data.call!, accessLevel: AuthorizationLevelManager().getAccessLevel(model: PhoneCallObject().createTerritoryObject(from: data.call!)) ?? .User))
                }
            }
        }
    }
}
