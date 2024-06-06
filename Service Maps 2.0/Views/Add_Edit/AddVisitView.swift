//
//  AddVisitView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    var visit: VisitModel?
    
    @StateObject var viewModel: AddVisitViewModel
    @State var title = ""
    
    init(visit: VisitModel?, house: HouseModel, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        let initialViewModel = AddVisitViewModel(house: house)
        _viewModel = StateObject(wrappedValue: initialViewModel)
        if let visit = visit {
            self.visit = visit
        }
        
        self.onDone = onDone
        self.onDismiss = onDismiss
    }
    
    var onDone: () -> Void
    var onDismiss: () -> Void
    
    @FocusState var notesFocus: Bool
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("\(title) Visit")
                        .font(.title3)
                        .fontWeight(.bold)
                        .hSpacing(.leading)
                        .padding(.leading)
                    
                   
                }
                
                HStack {
                    
                    Text("Symbol: ")
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                    Menu { // Use a Menu instead of a Button
                        ForEach(Symbols.allCases, id: \.self) { option in
                                    Button(action: {
                                        viewModel.selectedOption = option
                                    }) {
                                        HStack {
                                            Text(option.rawValue)
                                            if viewModel.selectedOption == option {
                                                Spacer()
                                                Image(systemName: "checkmark") // Add a checkmark for the selected option
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedOption.rawValue)
                                        .foregroundColor(.primary)
                                        .padding(10)
                                    
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                )
                            }
                }.hSpacing(.leading).padding(.leading, 16)
                
                
                CustomField(text: $viewModel.notes, isFocused: $notesFocus, textfield: true, textfieldAxis: .vertical, expanded: true, placeholder: NSLocalizedString("Notes", comment: ""))
                    .padding(.bottom)
                
                if viewModel.error != "" {
                    Text(viewModel.error)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() { onDismiss() }.keyboardShortcut("\r", modifiers: [.command, .shift])
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                        if viewModel.checkInfo() {
                            if visit != nil {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editVisit(visit: visit!)
                                    switch result {
                                    case .success(_):
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = NSLocalizedString("Error updating Visit.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            } else {
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.addVisit()
                                    switch result {
                                    case .success(_):
                                        onDone()
                                    case .failure(_):
                                        viewModel.error = NSLocalizedString("Error adding Visit.", comment: "")
                                        viewModel.loading = false
                                    }
                                }
                            }
                        }
                    }.keyboardShortcut("\r", modifiers: .command)
                }
                .padding([.horizontal, .bottom])
                //.vSpacing(.bottom)
                
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitle("\(title) Visit", displayMode: .large)
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
                if visit != nil {
                    //withAnimation {
                    title = NSLocalizedString("Edit", comment: "")
                    self.viewModel.notes = visit!.notes                    //}
                    self.viewModel.selectedOption = Symbols(rawValue: visit!.symbol.uppercased()) ?? .none
                } else {
                    //withAnimation {
                    title = NSLocalizedString("Add", comment: "")
                    //}
                }
            }
    }
    
}


