//
//  StorageManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/8/23.
//

import Foundation

class StorageManager: ObservableObject {
    //static let shared = StorageManager()
    let defaults = UserDefaults.standard
    
    init() {
        readValuesFromUserDefaults()
    }
    
    //MARK: Keys
    private var userEmailKey = "userEmailKey"
    private var userNameKey = "userNameKey"
    private var congregationnameKey = "congregationnameKey"
    private var passTempKey = "passTempKey"
    private var synchronizedKey = "synchronizedKey"
    private var pendingChangesKey = "pendingChangesKey"
    
    //MARK: Published Variables
    @Published var userEmail: String? = nil {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.userEmail, forKey: self.userEmailKey)
                self.objectWillChange.send()
            }
        }
        
    }
    @Published var userName: String? = nil {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.userName, forKey: self.userNameKey)
                self.objectWillChange.send()
            }
        }
    }
    @Published var congregationName: String? = nil {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.congregationName, forKey: self.congregationnameKey)
                self.objectWillChange.send()
            }
        }
    }
    @Published var passTemp: String? = nil {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.passTemp, forKey: self.passTempKey)
                self.objectWillChange.send()
            }
        }
    }
    
    @Published var synchronized = false {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.synchronized, forKey: self.synchronizedKey)
                self.objectWillChange.send()
            }
        }
    }
    
    @Published var pendingChanges = [PendingChange]() {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.pendingChanges, forKey: self.pendingChangesKey)
                self.objectWillChange.send()
            }
        }
    }
    
    private func readValuesFromUserDefaults() {
        self.userEmail = defaults.string(forKey: userEmailKey)
        self.userName = defaults.string(forKey: userNameKey)
        self.congregationName = defaults.string(forKey: congregationnameKey)
        self.passTemp = defaults.string(forKey: passTempKey)
        self.synchronized = defaults.bool(forKey: synchronizedKey)
        if let data = defaults.data(forKey: pendingChangesKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()

                // Decode Note
                _ = try decoder.decode([PendingChange].self, from: data)

            } catch {
                print("Unable to Decode Note (\(error))")
            }
        }
    }
    
    func clear() {
        userEmail = nil
        userName = nil
        congregationName = nil
        passTemp = nil
        synchronized = false
    }
    
    class var shared: StorageManager {
        struct Static {
            static let instance = StorageManager()
        }
        
        return Static.instance
    }
}
