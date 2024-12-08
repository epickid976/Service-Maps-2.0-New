//
//  AddPhoneNumberScreen.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import SwiftUI

//MARK: - AddPhoneNumberScreen

struct AddPhoneNumberScreen: View {
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    //MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: AddPhoneNumberViewModel
    
    //MARK: - Properties
    
    @FocusState private var numberTextFocus: Bool
    @FocusState private var houseTextFocus: Bool
    
    var number: PhoneNumber?
    
    @State var title = ""
    
    //MARK: - Init
    
    init(territory: PhoneTerritory, number: PhoneNumber?, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddPhoneNumberViewModel(territory: territory))
        if let number = number {
            self.number = number
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    //MARK: - Body
    
    var body: some View {
        ZStack {
            VStack {
                Text("\(title) Phone Number")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .hSpacing(.center)
                Text("Number")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                //.frame(alignment: .leading)
                //.hSpacing(.center)
                    .padding(.leading)
                CustomField(text: $viewModel.numberText, isFocused: $numberTextFocus, textfield: true, keyboardType: .numberPad, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, formatAsPhone: true, placeholder: "#")
                    .padding(.bottom)
                Text("House")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                //.frame(alignment: .leading)
                //.hSpacing(.center)
                    .padding(.leading)
                CustomField(text: $viewModel.houseText, isFocused: $houseTextFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, placeholder: NSLocalizedString("House", comment: ""))
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
                            if number != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editNumber(number: number!)
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error updating phone number.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            } else {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.addNumber()
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        onDone()
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error adding phone number.", comment: "")
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
            .navigationBarTitle("\(title) Number", displayMode: .large)
            .navigationBarBackButtonHidden()
            
        }.ignoresSafeArea(.keyboard)
            .onAppear {
                if number != nil {
                    //withAnimation {
                    title = NSLocalizedString("Edit", comment: "")
                    self.viewModel.numberText = number!.number
                    self.viewModel.houseText = number!.house ?? ""
                    //}
                } else {
                    //withAnimation {
                    title = NSLocalizedString("Add", comment: "")
                    //}
                }
            }
    }
}

//MARK: - AddPhoneNumberViewModel

@MainActor
class AddPhoneNumberViewModel: ObservableObject {
    
    //MARK: - Init
    
    init(territory: PhoneTerritory) {
        error = ""
        self.territory = territory
    }
    
    //MARK: - Dependencies
    
    @Published private var dataUploader = DataUploaderManager()
    
    //MARK: - Properties
    
    @Published var territory: PhoneTerritory
    
    @Published var error = ""
    @Published var numberText = ""
    @Published var houseText = ""
    
    @Published var loading = false
    
    //MARK: - Methods
    
    func addNumber() async -> Result<Void, Error> {
        loading = true
        let numberObject = PhoneNumber(id: territory.id + String(Date().timeIntervalSince1970 * 1000), congregation: territory.congregation, number: numberText.removeFormatting(), territory: territory.id, house: houseText == "" ? nil : houseText)
        return await dataUploader.addPhoneNumber(phoneNumber: numberObject)
    }
    
    func editNumber(number: PhoneNumber) async -> Result<Void, Error> {
        loading = true
        let numberObject = PhoneNumber(id: number.id, congregation: number.congregation, number: numberText.removeFormatting(), territory: number.territory, house: houseText == "" ? nil : houseText)
        return await dataUploader.updatePhoneNumber(phoneNumber: numberObject)
    }
    
    func checkInfo() -> Bool {
        if numberText == "" {
            error = NSLocalizedString("Phone Number is required.", comment: "")
            return false
        } else if !numberText.isValidPhoneNumber() {
            error = NSLocalizedString("That is not a valid phone number.", comment: "")
            return false
        } else {
            return true
        }
    }
}
