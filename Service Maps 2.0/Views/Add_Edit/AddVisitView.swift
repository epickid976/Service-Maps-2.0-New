//
//  AddVisitView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/25/23.
//

import SwiftUI

struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    var visit: Visit?
    
    @StateObject var viewModel: AddVisitViewModel
    @State var title = ""
    
    init(visit: Visit?, house: House, onDone: @escaping () -> Void, onDismiss: @escaping () -> Void) {
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
    
    @State var showOptions = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("\(title) Visit")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .hSpacing(.center)
                        
                   
                }
                
                CustomPickerView(viewModel: viewModel, showOptions: $showOptions, text: $viewModel.notes)
                    .padding(.bottom, !showOptions ? 0 : 16)
                    .padding(.bottom, viewModel.error != "" ? 30 : 0)
                
                if !showOptions {
                    CustomField(text: $viewModel.notes, isFocused: $notesFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, expanded: true, placeholder: NSLocalizedString("Notes", comment: ""))
                        .padding(.bottom)
                    
                    if viewModel.error != "" {
                        Text(viewModel.error)
                            .padding(.top, 20)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                HStack {
                    if !viewModel.loading {
                        CustomBackButton() { onDismiss(); HapticManager.shared.trigger(.lightImpact) }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                    }
                    //.padding([.top])
                    
                    CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                        HapticManager.shared.trigger(.lightImpact)
                        if viewModel.checkInfo() {
                            if visit != nil {
                                notesFocus = false
                                Task {
                                    withAnimation {
                                        viewModel.loading = true
                                    }
                                    let result = await viewModel.editVisit(visit: visit!)
                                    switch result {
                                    case .success(_):
                                        HapticManager.shared.trigger(.success)
                                        DispatchQueue.main.async {
                                            onDone()
                                        }
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
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
                                        HapticManager.shared.trigger(.success)
                                        DispatchQueue.main.async {
                                            onDone()
                                        }
                                    case .failure(_):
                                        HapticManager.shared.trigger(.error)
                                        viewModel.error = NSLocalizedString("Error adding Visit.", comment: "")
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
            .navigationBarTitle("\(title) Visit", displayMode: .large)
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


struct CustomPickerView: View {
    @ObservedObject var viewModel: AddVisitViewModel
    @Binding var showOptions: Bool
    @Binding var text: String
   
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack {
            HStack {
                Text("\(text.count)/255")
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                    .padding(.leading, 10)
                Spacer()
                Text("Symbol: ")
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .fontWeight(.heavy)
                Button(action: {
                    withAnimation {
                        showOptions.toggle()
                    }
                }) {
                    HStack {
                        Text(NSLocalizedString(viewModel.selectedOption.rawValue, comment: ""))
                            .foregroundColor(.primary)
                            .padding(10)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)

            if showOptions {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Symbols.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel.selectedOption = option
                            withAnimation {
                                showOptions = false
                            }
                        }) {
                            HStack {
                                Text("**\(option.rawValue == "-" ? "" : NSLocalizedString(option.rawValue, comment: ""))** - \(option.legend)")
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .font(.body)
                                    .frame(alignment: .leading)
                                    //.fontWeight(.bold)
                                    
                            }.hSpacing(.center).animation(.spring(), value: viewModel.selectedOption == option)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 50) // Ensure same height
                            .background(
                                RoundedRectangle(cornerRadius: 40)
                                    .fill(Color.gray.opacity( viewModel.selectedOption == option ? 0.2 : 0.1))
                                    
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 40)
                                    .stroke(viewModel.selectedOption == option ? Color.white : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.leading, 16)
                
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
