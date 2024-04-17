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
    
    @ObservedObject var viewModel: AddVisitViewModel
    @State var title = "Add"
    
    init() {
        let initialViewModel = AddVisitViewModel()
        _viewModel = ObservedObject(wrappedValue: initialViewModel)
        if let visit = visit {
            self.viewModel.notes = visit.notes ?? ""
            self.viewModel.selectedDate = Date(timeIntervalSinceNow: (Double(visit.date) / 1000))
            self.viewModel.selectedOption = Symbols(rawValue: visit.symbol!) ?? .NC
            title = "Edit"
        }
    }
    
    @FocusState var notesFocus: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                //Visit will be added to current house.
                
                Text("Visit will be added to current house.")
                    .font(.headline)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                
                Divider().padding([.horizontal, .bottom])
                
                HStack {
                    VStack {
                        Text("Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                        //.frame(alignment: .leading)
                            .hSpacing(.center)
                        //.padding(.leading)
                        DatePicker("", selection: $viewModel.selectedDate)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }.padding(.leading)
                    
                    VStack {
                        Text("Symbol")
                            .font(.headline)
                            .fontWeight(.semibold)
                        //.frame(alignment: .leading)
                            .hSpacing(.center)
                        //.padding(.leading)
                        Picker("Symbols", selection: $viewModel.selectedOption) {
                            ForEach(Symbols.allCases) { option in
                                Text(String(describing: option))
                            }
                        }
                        .pickerStyle(.menu)
                        .buttonStyle(.bordered)
                        .tint(.primary)
                    }.padding(.trailing)
                }
                .padding(.bottom)
                
                Text("Notes")
                    .font(.headline)
                    .fontWeight(.semibold)
                // .frame(alignment: .center)
                    .hSpacing(.center)
                //.padding(.leading)
                CustomField(text: $viewModel.notes, isFocused: $notesFocus, textfield: true, textfieldAxis: .vertical, placeholder: "Notes")
                    .animation(.spring, value: viewModel.notes)
                
                VStack {
                    HStack {
                            CustomBackButton() { dismiss() }
                            //.padding([.top])
                        
                        CustomButton(loading: false, title: "Save") {
                            
                        }
                    }
                    .padding()
                }.vSpacing(.bottom)
                
            }
            .navigationBarTitle("Add Visit", displayMode: .large)
            .vSpacing(.top)
        }
        
    }
    
}

#Preview {
    NavigationStack {
        @State var present = true
        VStack {
            AddVisitView()
        }
        .sheet(isPresented: $present) {
            AddVisitView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
           
    }
    
}

