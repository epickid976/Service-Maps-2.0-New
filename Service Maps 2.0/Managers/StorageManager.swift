//
// StorageManager.swift
// Service Maps 2.0
//
// Created by Jose Blanco on 8/8/23.
//

import Foundation

//MARK: - Storage Manager

@MainActor
class StorageManager: ObservableObject, @unchecked Sendable {
    //MARK: - Singleton
    static let shared = StorageManager()
    
    //MARK: - Properties
    let defaults = UserDefaults.standard
    
    //MARK: - Initialization
    init() {
        readValuesFromUserDefaults()
    }
    
    //MARK: Keys
    private let userEmailKey = "userEmailKey"
    private let userNameKey = "userNameKey"
    private let congregationnameKey = "congregationnameKey"
    private let passTempKey = "passTempKey"
    private let synchronizedKey = "synchronizedKey"
    private let pendingChangesKey = "pendingChangesKey"
    private let lastTimeKey = "lastSyncKey"
    private let phoneCongregationNameKey = "phoneCongregationNameKey"
    
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
    
    @Published var phoneCongregationName: String? = nil {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.phoneCongregationName, forKey: self.phoneCongregationNameKey)
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
    
    @Published var lastTime: Date? {
        didSet {
            DispatchQueue.main.async {
                self.defaults.set(self.lastTime, forKey: self.lastTimeKey)
                self.objectWillChange.send()
            }
        }
    }
    
    //MARK: - Read Values
    private func readValuesFromUserDefaults() {
        self.userEmail = defaults.string(forKey: userEmailKey)
        self.userName = defaults.string(forKey: userNameKey)
        self.congregationName = defaults.string(forKey: congregationnameKey)
        self.passTemp = defaults.string(forKey: passTempKey)
        self.synchronized = defaults.bool(forKey: synchronizedKey)
        self.phoneCongregationName = defaults.string(forKey: phoneCongregationNameKey)
    }
    
    //MARK: - Clear'
    func clear() {
        userEmail = nil
        userName = nil
        congregationName = nil
        passTemp = nil
        synchronized = false
        lastTime = nil
    }
}
