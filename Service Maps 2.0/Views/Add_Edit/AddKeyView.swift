//
//  AddKeyView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/23/24.
//

import Foundation
import SwiftUI
import Lottie
import NavigationTransitions

struct AddKeyView: View {
    var onDone: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AddKeyViewModel
    @Environment(\.mainWindowSize) var mainWindowSize
    @FocusState private var nameFocus: Bool
    
    init(keyData: KeyData?, onDone: @escaping () -> Void) {
        self.keyData = keyData
        let viewModel = AddKeyViewModel(keyData: keyData)
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDone = onDone
    }
    @StateObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var keyData: KeyData?
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if viewModel.territoryData == nil || dataStore.synchronized == false {
                    if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                        LottieView(animation: .named("loadsimple"))
                            .playing()
                            .resizable()
                            .frame(width: 250, height: 250)
                    } else {
                        LottieView(animation: .named("loadsimple"))
                            .playing()
                            .resizable()
                            .frame(width: 350, height: 350)
                    }
                } else {
                    if viewModel.territoryData!.isEmpty {
                        VStack {
                            if UIDevice.modelName == "iPhone 8" || UIDevice.modelName == "iPhone SE (2nd generation)" || UIDevice.modelName == "iPhone SE (3rd generation)" {
                                LottieView(animation: .named("nodatapreview"))
                                    .playing()
                                    .resizable()
                                    .frame(width: 250, height: 250)
                            } else {
                                LottieView(animation: .named("nodatapreview"))
                                    .playing()
                                    .resizable()
                                    .frame(width: 350, height: 350)
                            }
                        }
                        
                    } else {
                        Text(viewModel.error)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        HStack {
                            Text("Name")
                                .font(.title3)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                                .padding(.leading)
                            
                            VStack {
                                Toggle(isOn: $viewModel.servant) {
                                    Text("Servant")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .hSpacing(.trailing)
                                }
                                .toggleStyle(CheckmarkToggleStyle())
                                .disabled(keyData != nil)
                                //.padding()
                            }
                        }
                        if keyData != nil {
                            Text(keyData!.key.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                                .padding(.leading)
                        } else {
                            CustomField(text: $viewModel.name, isFocused: $nameFocus, textfield: true, textfieldAxis: .vertical, placeholder: NSLocalizedString("Key Name", comment: ""))
                        }
                        ScrollView {
                            LazyVStack {
                                ForEach(viewModel.territoryData!) { dataWithKey in
                                    viewModel.showSelectableTerritoriesList(dataWithKeys: dataWithKey, mainWindowSize: proxy.size)
                                }
                            }
                        }
                        
                        HStack {
                            if !viewModel.loading {
                                CustomBackButton() { presentationMode.wrappedValue.dismiss() }.keyboardShortcut("\r", modifiers: [.command, .shift])
                            }
                            //.padding([.top])
                            
                            CustomButton(loading: viewModel.loading, title: NSLocalizedString(keyData != nil ? "Edit" : "Add", comment: "")) {
                                if viewModel.checkInfo() {
                                    Task {
                                        withAnimation {
                                            viewModel.loading = true
                                        }
                                        let result = await viewModel.addToken()
                                        switch result {
                                        case .success(_):
                                            onDone()
                                            presentationMode.wrappedValue.dismiss()
                                        case .failure(_):
                                            viewModel.error = NSLocalizedString("Error adding/updating key.", comment: "")
                                            viewModel.loading = false
                                        }
                                    }
                                    
                                }
                            }.keyboardShortcut("\r", modifiers: .command)
                        }
                        .padding([.horizontal, .bottom])
                    }
                }
            }
            .navigationBarTitle("Add Key", displayMode: .automatic)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct CheckmarkToggleStyle: ToggleStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .foregroundColor(configuration.isOn ? .teal : Color(UIColor.darkGray))
                .frame(width: 51, height: 31, alignment: .center)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .padding(.all, 3)
                        .overlay(
                            Image(systemName: configuration.isOn ? "checkmark" : "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .font(Font.title.weight(.black))
                                .frame(width: 8, height: 8, alignment: .center)
                                .foregroundColor(configuration.isOn ? .teal : .gray)
                        )
                        .offset(x: configuration.isOn ? 11 : -11, y: 0)
                        .animation(Animation.linear(duration: 0.1))
                    
                ).cornerRadius(20)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
    
}
