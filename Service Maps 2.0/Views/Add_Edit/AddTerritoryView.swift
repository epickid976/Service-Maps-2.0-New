//
//  AddTerritoryView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/20/23.
//

import SwiftUI
import PhotosUI
import NavigationTransitions
import Nuke
import Combine

//MARK: - AddTerritoryView

struct AddTerritoryView: View {
    var territory: Territory?
    
    //MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: AddTerritoryViewModel
    
    //MARK: - Initializers
    
    init(territory: Territory?, onDone: @escaping () -> Void) {
        if let territory = territory {
            self.territory = territory
            _viewModel = StateObject(wrappedValue: AddTerritoryViewModel(territory: territory))
        } else {
            _viewModel = StateObject(wrappedValue:AddTerritoryViewModel())
        }
        
        self.onDone = onDone
    }
    
    //MARK: - Properties
    
    @State var title = ""
    @FocusState private var numberFocus: Bool
    @FocusState private var descriptionFocus: Bool
    
    var onDone: () -> Void
    
    //MARK: - Body
    
    var body: some View {
            ZStack {
                NavigationStack {
                    VStack {
                        VStack {
                            Text("Number")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .hSpacing(.leading)
                                .padding(.leading)
                            HStack {
                                CustomField(text: viewModel.binding, isFocused: $numberFocus, textfield: true, keyboardType: .numberPad, textAlignment: .center, placeholder: "#")
                                    .frame(maxWidth: UIScreen.screenWidth * 0.3)
                                    .disabled(title == "Edit")
                                if title != "Edit" {
                                    Stepper("", onIncrement: {
                                        HapticManager.shared.trigger(.lightImpact)
                                        if viewModel.number != nil {
                                            viewModel.number! += 1
                                        } else {
                                            viewModel.number = 0
                                        }
                                        
                                    }, onDecrement: {
                                        HapticManager.shared.trigger(.softError)
                                        if viewModel.number != nil {
                                            if viewModel.number != 0 {
                                                viewModel.number! -= 1
                                            }
                                        }
                                    })
                                    .scaleEffect(CGSize(width: 1.5, height: 1.5))
                                    .labelsHidden()
                                    .frame(maxWidth: UIScreen.screenWidth * 0.3)
                                } else {
                                    Text("Number Uneditable")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .hSpacing(.leading)
                                        .foregroundColor(.red)
                                }
                            }
                            .hSpacing(.leading)
                        }
                        .padding(.vertical)
                        
                        Text("Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                        // .frame(alignment: .center)
                            .hSpacing(.leading)
                            .padding(.leading)
                        CustomField(text: $viewModel.description, isFocused: $descriptionFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, placeholder: NSLocalizedString("Description", comment: ""))
                            .animation(.spring(), value: viewModel.description)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity).animation(.spring()),
                                removal: .opacity.animation(.easeInOut)
                            ))
                            .padding(.bottom)
                        
                        Text("Image")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .hSpacing(.center)
                        VStack {
                            ImagePickerView(title: NSLocalizedString("Drag & Drop", comment: ""), subTitle: NSLocalizedString("Tap to add an image", comment: ""), systemImage: "person.crop.square.badge.camera", tint: .blue, previewImage: $viewModel.previewImage) { image in
                                viewModel.imageToSend = image
                            }
                            .optionalViewModifier { content in
                                content
                                    .overlay(
                                        Button {
                                            HapticManager.shared.trigger(.lightImpact)
                                            DispatchQueue.main.async {
                                                viewModel.imageToSend = nil
                                                viewModel.previewImage = nil
                                                content.previewImage = nil
                                            }
                                        } label: {
                                            if viewModel.imageToSend != nil {
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.red)
                                                    .padding(8)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                            }
                                        }
                                            .offset(x: 10, y: -10),
                                        alignment: .topTrailing
                                    )
                            }
                            
                        }
                        .frame(minWidth: 250, maxWidth: 300, minHeight: 10, maxHeight: 300)
                        
                        Text(viewModel.error)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .vSpacing(.bottom)
                        
                        HStack {
                            if !viewModel.loading {
                                CustomBackButton() { dismiss(); HapticManager.shared.trigger(.lightImpact) }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                            }
                            //.padding([.top])
                            
                            CustomButton(loading: viewModel.loading, title: NSLocalizedString("Save", comment: "")) {
                                HapticManager.shared.trigger(.lightImpact)
                                if viewModel.checkInfo() {
                                    withAnimation { viewModel.loading = true }
                                    if territory != nil {
                                        Task {
                                            try? await Task.sleep(nanoseconds: 300_000_000) // 150ms delay — tweak as needed
                                            let result = await viewModel.editTerritory(territory: territory!)
                                            switch result {
                                            case .success:
                                                HapticManager.shared.trigger(.success)
                                                dismiss()
                                                onDone()
                                            case .failure(_):
                                                HapticManager.shared.trigger(.error)
                                                viewModel.error = NSLocalizedString("Error updating territory.", comment: "")
                                                viewModel.loading = false
                                            }
                                        }
                                    } else {
                                        Task {
                                            try? await Task.sleep(nanoseconds: 300_000_000) // 150ms delay — tweak as needed
                                            let result = await viewModel.addTerritory()
                                            switch result {
                                            case .success:
                                                HapticManager.shared.trigger(.success)
                                                dismiss()
                                                onDone()
                                            case .failure(_):
                                                HapticManager.shared.trigger(.error)
                                                viewModel.error = NSLocalizedString("Error adding territory.", comment: "")
                                                viewModel.loading = false
                                            }
                                        }
                                    }
                                }
                            }//.keyboardShortcut("\r", modifiers: .command)
                        }
                        .padding([.horizontal, .bottom])
                        .vSpacing(.bottom)
                        
                    }
                    
                    .ignoresSafeArea(.keyboard)
                    .navigationBarTitle("\(title) Territory", displayMode: .large)
                    .navigationBarBackButtonHidden()
                }
                .navigationTransition(
                    .zoom.combined(with: .fade(.out))
                )
                
            }//.ignoresSafeArea(.keyboard)
            .onAppear {
                if territory != nil {
                    withAnimation {
                        title = NSLocalizedString("Edit", comment: "")
                        
                    }
                    self.viewModel.description = territory!.description
                    self.viewModel.number = Int(territory!.number)
                } else {
                    withAnimation {
                        title = NSLocalizedString("Add", comment: "")
                    }
                }
            }
    }
}
