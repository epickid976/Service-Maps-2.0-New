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
    
    @ObservedObject var universalLinksManager = UniversalLinksManager.shared
    
    @ObservedObject var authenticationManager = AuthenticationManager()
    
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
    
    
    
    
    @MainActor
    func registerKey() async -> Result<Bool, Error> {
        return await dataUploaderManager.registerToken(myToken: universalLinksManager.dataFromUrl ?? "")
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
