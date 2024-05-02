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
                    .font(.title)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(.leading)
                Text("Number")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                //.frame(alignment: .leading)
                //.hSpacing(.center)
                    .padding(.leading)
                CustomField(text: $viewModel.numberText, isFocused: $numberTextFocus, textfield: true, keyboardType: .numberPad, textfieldAxis: .vertical, formatAsPhone: true, placeholder: "#")
                    .padding(.bottom)
                Text("House")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .hSpacing(.leading)
                //.frame(alignment: .leading)
                //.hSpacing(.center)
                    .padding(.leading)
                CustomField(text: $viewModel.houseText, isFocused: $houseTextFocus, textfield: true, textfieldAxis: .vertical, placeholder: "House")
                    .padding(.bottom)
                
                Text(viewModel.error)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                //.vSpacing(.bottom)
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() { onDismiss() }
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: "Save") {
                        if viewModel.checkInfo() {
                            if number != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editNumber(number: number!)
                                    switch result {
                                    case .success(_):
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = "Error updating phone number."
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
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = "Error adding phone number."
                                        viewModel.loading = false
                                    }
                                }
                            }
                        }
                    }
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
                    title = "Edit"
                    self.viewModel.numberText = number!.number
                    self.viewModel.houseText = number!.house ?? ""
                    //}
                } else {
                    //withAnimation {
                    title = "Add"
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
            error = "Phone Number is required."
            return false
        } else if !numberText.isValidPhoneNumber() {
            error = "That is not a valid phone number."
            return false
        } else {
            return true
        }
    }
}
