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

//MARK: - AddKeyView
struct AddKeyView: View {
    var onDone: () -> Void
    
    //MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.mainWindowSize) var mainWindowSize
    
    //MARK: - Dependencies
    
    @StateObject var viewModel: AddKeyViewModel
    @StateObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    //MARK: - Initializers
    
    init(keyData: KeyData?, onDone: @escaping () -> Void) {
        self.keyData = keyData
        let viewModel = AddKeyViewModel(keyData: keyData)
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDone = onDone
    }
    
    //MARK: - Properties
    
    @FocusState private var nameFocus: Bool
    @State var animationDone = false
    @State var animationProgressTime: AnimationProgressTime = 0
    @State var keyData: KeyData?
    
    //MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                if viewModel.territoryData == nil && !dataStore.synchronized {
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
                    if let territoryData = viewModel.territoryData {
                        if territoryData.isEmpty {
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
                            .onChange(of: viewModel.servant) { _ in
                                HapticManager.shared.trigger(.lightImpact)
                            }
                            if keyData != nil {
                                Text(keyData!.key.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .hSpacing(.leading)
                                    .padding(.leading)
                            } else {
                                CustomField(text: $viewModel.name, isFocused: $nameFocus, textfield: true, keyboardContentType: .oneTimeCode, textfieldAxis: .vertical, placeholder: NSLocalizedString("Key Name", comment: ""))
                            }
                            ScrollView {
                                LazyVStack {
                                    ForEach(territoryData, id: \.id) { dataWithKey in
                                        showSelectableTerritoriesList(dataWithKeys: dataWithKey, mainWindowSize: proxy.size).id(dataWithKey.id)
                                    }
                                }
                            }
                            
                            HStack {
                                if !viewModel.loading {
                                    CustomBackButton() { presentationMode.wrappedValue.dismiss(); HapticManager.shared.trigger(.lightImpact) }//.keyboardShortcut("\r", modifiers: [.command, .shift])
                                }
                                //.padding([.top])
                                
                                CustomButton(loading: viewModel.loading, title: NSLocalizedString(keyData != nil ? "Edit" : "Add", comment: "")) {
                                    HapticManager.shared.trigger(.lightImpact)
                                    if viewModel.checkInfo() {
                                        Task {
                                            withAnimation {
                                                viewModel.loading = true
                                            }
                                            let result = await viewModel.addToken()
                                            switch result {
                                            case .success(_):
                                                HapticManager.shared.trigger(.success)
                                                onDone()
                                                presentationMode.wrappedValue.dismiss()
                                            case .failure(_):
                                                HapticManager.shared.trigger(.error)
                                                viewModel.error = NSLocalizedString("Error adding/updating key.", comment: "")
                                                viewModel.loading = false
                                            }
                                        }
                                        
                                    }
                                }//.keyboardShortcut("\r", modifiers: .command)
                            }
                            .padding([.horizontal, .bottom])
                        }
                    }
                }
            }
            .navigationBarTitle("Add Key", displayMode: .automatic)
            .navigationBarBackButtonHidden(true)
        }
    }
    
    @ViewBuilder
    func SelectableTerritoryItem(territoryData: TerritoryData, mainWindowSize: CGSize) -> some View {
        Button(action: {
            self.viewModel.toggleSelection(for: territoryData)
        }) {
            HStack {
                Image(systemName: viewModel.isSelected(territoryData: territoryData) ? "checkmark.circle.fill" : "circle")
                    .optionalViewModifier { content in
                        if #available(iOS 17, *) {
                            content
                                .symbolEffect(.bounce, options: .speed(3.0), value: self.viewModel.isSelected(territoryData: territoryData))
                                .animation(.bouncy, value: self.viewModel.isSelected(territoryData: territoryData))
                        } else {
                            content
                                .animation(.bouncy, value: self.viewModel.isSelected(territoryData: territoryData))
                        }
                    }
                
                CellView(territory: territoryData.territory, houseQuantity: territoryData.housesQuantity, width: 0.8, mainWindowSize: mainWindowSize)
                    .padding(2)
            }
            .padding(.horizontal, 10)
        }.id(territoryData.territory.id)
            .buttonStyle(PlainButtonStyle()) // Maintains original appearance
    }
    
    @ViewBuilder
    func showSelectableTerritoriesList(dataWithKeys: TerritoryDataWithKeys, mainWindowSize: CGSize) -> some View {
        LazyVStack {
            if !dataWithKeys.keys.isEmpty {
                Text(self.viewModel.processData(dataWithKeys: dataWithKeys))
                    .font(.title2)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .hSpacing(.leading)
                    .padding(5)
                    .padding(.horizontal, 10)
            } else {
                Spacer()
                    .frame(height: 20)
            }
        }
        
        ForEach(dataWithKeys.territoriesData, id: \.territory.id) { territoryData in
            self.SelectableTerritoryItem(territoryData: territoryData, mainWindowSize: mainWindowSize).id(territoryData.territory.id)
        }
    }
}

//MARK: - Checkmark Toggle Style

struct CheckmarkToggleStyle: ToggleStyle {
    var color: Color = .teal
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .foregroundColor(configuration.isOn ? color : Color(UIColor.darkGray))
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
                                .foregroundColor(configuration.isOn ? color : .gray)
                        )
                        .offset(x: configuration.isOn ? 11 : -11, y: 0)
                        .animation(Animation.linear(duration: 0.1))
                    
                ).cornerRadius(20)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
