//
//  AddHouseView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/28/23.
//


import SwiftUI
import PhotosUI
import NavigationTransitions

struct AddHouseView: View {
    var house: HouseModel?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AddHouseViewModel
    
    @FocusState private var numberFocus: Bool
    @State var title = ""
    
    init(house: HouseModel?, address: TerritoryAddressModel, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddHouseViewModel(address: address))
        if let house = house {
            self.house = house
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
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
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        if viewModel.checkInfo() {
                            if house != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editHouse(house: house!)
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error updating house.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            } else {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.addHouse()
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error adding house.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            }
                        }
                    }//.keyboardShortcut("\r", modifiers: .command)
                }
                .padding([.horizontal, .bottom])
                //.vSpacing(.bottom)
                
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("\(title) House", displayMode: .large)
            .navigationBarBackButtonHidden()
            .toolbar{
                ToolbarItemGroup(placement: .keyboard){
                    Spacer()
                    Button {
                        HapticManager.shared.trigger(.lightImpact)
                        DispatchQueue.main.async {
                            hideKeyboard()
                        }
                    } label: {
                        Text("Done")
                            .tint(.primary)
                            .fontWeight(.bold)
                            .font(.body)
                    }
                }
            }
            
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

//#Preview {
//    AddHouseView(house: nil)
//}
