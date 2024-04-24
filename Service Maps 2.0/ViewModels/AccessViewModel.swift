//
//  AccessViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/9/24.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import NavigationTransitions
import SwipeActions
import RealmSwift

@MainActor
class AccessViewModel: ObservableObject {
    
    init() {
        getKeys()
    }
    @ObservedObject var synchronizationManager = SynchronizationManager.shared
    @ObservedObject var dataStore = StorageManager.shared
    @ObservedObject var dataUploaderManager = DataUploaderManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var keyData: Optional<[KeyData]> = nil
    
    @Published var isAdmin = AuthorizationLevelManager().existsAdminCredentials()
    
    @Published var currentToken: MyTokenModel?
    @Published var presentSheet = false {
        didSet {
            if presentSheet == false {
                currentToken = nil
            }
        }
    }
    
    @Published var optionsAnimation = false
    @Published var progress: CGFloat = 0.0
    
    @Published var syncAnimation = false
    @Published var syncAnimationprogress: CGFloat = 0.0
    
    @Published var restartAnimation = false
    @Published var animationProgress: Bool = false {
        didSet {
            print(animationProgress)
        }
    }
    
    @Published var showAlert = false
    @Published var ifFailed = false
    @Published var loading = false
    @Published var keyToDelete: (String?,String?)
    
    @Published var showToast = false
    @Published var showAddedToast = false
    
    func deleteKey(key: String) async -> Result<Bool, Error> {
        if !isAdmin {
            switch await dataUploaderManager.unregisterToken(myToken: key) {
            case .success(_):
                synchronizationManager.startupProcess(synchronizing: true)
                return Result.success(true)
            case .failure(let error):
                return Result.failure(error)
            }
        } else {
            return await dataUploaderManager.deleteToken(myToken: key)
        }
    }
    
    @ViewBuilder
    func keyCell(keyData: KeyData) -> some View {
        SwipeView {
                TokenCell(keyData: keyData)
                    .padding(.bottom, 2)
        } trailingActions: { context in
                SwipeAction(
                    systemImage: "trash",
                    backgroundColor: .red
                ) {
                    DispatchQueue.main.async {
                        self.keyToDelete = (keyData.key.id, keyData.key.name)
                        self.showAlert = true
                    }
                }
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
            
                SwipeAction(
                    systemImage: "square.and.arrow.up",
                    backgroundColor: Color.green
                ) {
                    context.state.wrappedValue = .closed
                    let url = URL(string: getShareLink(id: keyData.key.id))
                    let av = UIActivityViewController(activityItems: [url!], applicationActivities: nil)

                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                    
                }
                .allowSwipeToTrigger()
                .font(.title.weight(.semibold))
                .foregroundColor(.white)
        }
        .swipeActionCornerRadius(16)
        .swipeSpacing(5)
        .swipeOffsetCloseAnimation(stiffness: 500, damping: 100)
        .swipeOffsetExpandAnimation(stiffness: 500, damping: 100)
        .swipeOffsetTriggerAnimation(stiffness: 500, damping: 100)
        .swipeMinimumDistance(25)
    }
    
    @ViewBuilder
    func alert() -> some View {
        ZStack {
                VStack {
                    Text("Delete Key: \(keyToDelete.1 ?? "0")")
                        .font(.title)
                            .fontWeight(.heavy)
                            .hSpacing(.leading)
                        .padding(.leading)
                    Text("Are you sure you want to delete the selected key?")
                        .font(.title3)
                            .fontWeight(.bold)
                            .hSpacing(.leading)
                        .padding(.leading)
                    if ifFailed {
                        Text("Error deleting key, please try again later")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                            //.vSpacing(.bottom)
                    
                    HStack {
                        if !loading {
                            CustomBackButton() {
                                withAnimation {
                                    self.showAlert = false
                                    self.keyToDelete = (nil,nil)
                                }
                            }
                        }
                        //.padding([.top])
                        
                        CustomButton(loading: loading, title: "Delete", color: .red) {
                            withAnimation {
                                self.loading = true
                            }
                            Task {
                                if self.keyToDelete.0 != nil && self.keyToDelete.1 != nil {
                                    switch await self.deleteKey(key: self.keyToDelete.0 ?? "") {
                                    case .success(_):
                                        withAnimation {
                                            withAnimation {
                                                self.loading = false
                                                self.getKeys()
                                            }
                                            self.showAlert = false
                                            self.keyToDelete = (nil,nil)
                                            self.showToast = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                self.showToast = false
                                            }
                                        }
                                    case .failure(_):
                                        withAnimation {
                                            self.loading = false
                                        }
                                        self.ifFailed = true
                                    }
                                }
                            }
                            
                        }
                    }
                    .padding([.horizontal, .bottom])
                    //.vSpacing(.bottom)
                    
                }
                .ignoresSafeArea(.keyboard)
            
        }.ignoresSafeArea(.keyboard)
    }
    
}

@MainActor
extension AccessViewModel {
    func getKeys() {
        RealmManager.shared.getKeyData()
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
              if case .failure(let error) = completion {
                // Handle errors here
                print("Error retrieving territory data: \(error)")
              }
            }, receiveValue: { keyData in
              self.keyData = keyData
            })
            .store(in: &cancellables)
    }
}
