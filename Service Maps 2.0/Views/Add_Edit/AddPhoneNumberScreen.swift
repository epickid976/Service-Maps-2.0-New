//
//  AddPhoneNumberScreen.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import SwiftUI

struct AddPhoneNumberScreen: View {
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: AddPhoneNumberViewModel
    
    @FocusState private var numberTextFocus: Bool
    @FocusState private var houseTextFocus: Bool
    
    var number: PhoneNumberModel?
    
    @State var title = ""
    
    init(territory: PhoneTerritoryModel, number: PhoneNumberModel?, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddPhoneNumberViewModel(territory: territory))
        if let number = number {
            self.number = number
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
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


@MainActor
class AddPhoneNumberViewModel: ObservableObject {
    
    init(territory: PhoneTerritoryModel) {
        error = ""
        self.territory = territory
    }
    
    @Published private var dataUploader = DataUploaderManager()
    
    @Published var territory: PhoneTerritoryModel
    
    @Published var error = ""
    @Published var numberText = ""
    @Published var houseText = ""
    
    @Published var loading = false
    
    
    func addNumber() async -> Result<Bool, Error> {
        loading = true
        let numberObject = PhoneNumberObject()
        numberObject.id = territory.id + String(Date().timeIntervalSince1970 * 1000)
        numberObject.congregation = territory.congregation
        numberObject.number = numberText.removeFormatting()
        numberObject.house = houseText == "" ? nil : houseText
        numberObject.territory = territory.id
        return await dataUploader.addNumber(number: numberObject)
    }
    
    func editNumber(number: PhoneNumberModel) async -> Result<Bool, Error> {
        loading = true
        let numberObject = PhoneNumberObject()
        numberObject.id = number.id
        numberObject.congregation = number.congregation
        numberObject.number = numberText.removeFormatting()
        numberObject.house = houseText == "" ? nil : houseText
        numberObject.territory = number.territory
        return await dataUploader.updateNumber(number: numberObject)
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
