////
////  ColumnView.swift
////  Service Maps 2.0
////
////  Created by Jose Blanco on 6/20/24.
////
//
//import SwiftUI
//
//struct ColumnView: View {
//    var territory: Territory
//    
//    @ObservedObject var addressViewModel: AddressViewModel
//    @ObservedObject var householdViewModel: HousesViewModel
//    @ObservedObject var visitViewModel: VisitsViewModel
//    
//    @State private var selectedAddress: TerritoryAddress?
//    @State private var selectedHouse: House?
//    
//    init(territory: Territory) {
//        self.territory = territory
//                
//                let addressViewModel = AddressViewModel(territory: territory)
//                self.addressViewModel = addressViewModel
//                
//                if let firstAddress = addressViewModel.addressData?.first {
//                    self._householdViewModel = ObservedObject(initialValue: HousesViewModel(territoryAddress: firstAddress.address))
//                    if let firstHouse = _householdViewModel.wrappedValue.houseData?.first {
//                        self._visitViewModel = ObservedObject(initialValue: VisitsViewModel(house: firstHouse.house))
//                        _selectedHouse = State(initialValue: firstHouse.house)
//                    } else {
//                        self._visitViewModel = ObservedObject(initialValue:VisitsViewModel(house: House(id: "0", territory_address: "", number: "", created_at: "", updated_at: "")))
//                    }
//                    _selectedAddress = State(initialValue: firstAddress.address)
//                } else {
//                    self.householdViewModel = HousesViewModel(territoryAddress: TerritoryAddress(id: "0", territory: "", address: "", created_at: "", updated_at: ""))
//                    self.visitViewModel = VisitsViewModel(house: House(id: "0", territory_address: "", number: "", created_at: "", updated_at: ""))
//                }
//    }
//    var body: some View {
//        NavigationSplitView {
//            TerritoryAddressView(territory: territory)
//        } content: {
//            if let selectedAddress = selectedAddress {
//                HousesView(address: selectedAddress)
//            } else {
//                Text("No address selected")
//            }
//        } detail: {
//            if let selectedHouse = selectedHouse {
//                VisitsView(house: selectedHouse)
//            } else {
//                Text("No house selected")
//            }
//        }
//
//    }
//}
//
