//
//  AddHouseView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/28/23.
//


import SwiftUI
import PhotosUI
import NavigationTransitions

//MARK: - AddHouseView

struct AddHouseView: View {
    var house: House?
    
    //MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: AddHouseViewModel
    
    //MARK: - Initializers
    
    init(house: House?, address: TerritoryAddress, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddHouseViewModel(address: address))
        if let house = house {
            self.house = house
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    //MARK: - Properties
    
    @FocusState private var numberFocus: Bool
    @State var title = ""
    
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            VStack {
                Text("\(title) House")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.center)
                CustomField(text: $viewModel.number, isFocused: $numberFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, placeholder: NSLocalizedString("Number", comment: ""))
                    .padding(.bottom)
                
                Text(viewModel.error)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() { onDismiss(); HapticManager.shared.trigger(.lightImpact) }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                    }
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        if viewModel.checkInfo() {
                            if house != nil {
//                                Task {
//                                    withAnimation {
//                                        viewModel.loading = true
//                                    }
//                                    let result = await viewModel.editHouse(house: house!)
//                                    switch result {
//                                    case .success(_):
//                                        HapticManager.shared.trigger(.success)
//                                        onDone()
//                                    case .failure(_):
//                                        HapticManager.shared.trigger(.error)
//                                        viewModel.error = NSLocalizedString("Error updating house.", comment: "")
//                                        viewModel.loading = false
//                                    }
//                                }
                            } else {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    try? await Task.sleep(nanoseconds: 300_000_000) // 150ms delay — tweak as needed
                                    let result = await viewModel.addHouse()
                                    switch result {
                                    case .success:
                                        HapticManager.shared.trigger(.success)
                                        DispatchQueue.main.async {
                                            onDone()
                                        }
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error adding house.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
               
                
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("\(title) House", displayMode: .large)
            .navigationBarBackButtonHidden()
            
        }.ignoresSafeArea(.keyboard)
            .onAppear {
                if house != nil {
                    //withAnimation {
                    title = NSLocalizedString("Edit", comment: "")
                    self.viewModel.number = house!.number
                    //}
                } else {
                    //withAnimation {
                    title = NSLocalizedString("Add", comment: "")
                    //}
                }
            }
        
    }
}
