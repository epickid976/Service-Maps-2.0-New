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
                            .font(.title)
                            .fontWeight(.bold)
                            .hSpacing(.leading)
                            .padding(.leading)
                            .frame(maxWidth: UIScreen.screenWidth * 0.7, maxHeight: 100)
                        
                        HStack {
                            Text("Symbol: ")
                                .font(.subheadline)
                                .lineLimit(2)
                                .foregroundColor(.primary)
                                .fontWeight(.heavy)
                                .hSpacing(.leading)
                            Picker("Select Symbol", selection: $viewModel.selectedOption) {
                                ForEach(Symbols.allCases) { symbol in
                                    Text(symbol.rawValue)
                                        .tag(symbol)
                                }
                            }
                        }
                        .frame(maxWidth: UIScreen.screenWidth * 0.3, maxHeight: 100)
                    }
                    CustomField(text: $viewModel.notes, isFocused: $notesFocus, textfield: true, textfieldAxis: .vertical, placeholder: "Notes")
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
                                            viewModel.error = "Error updating Visit."
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
                                            viewModel.error = "Error adding Visit."
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
                        title = "Edit"
                    self.viewModel.notes = visit!.notes                    //}
                    self.viewModel.selectedOption = Symbols(rawValue: visit!.symbol.uppercased()) ?? .none
                } else {
                    //withAnimation {
                        title = "Add"
                    //}
                }
            }
    }
    
}


