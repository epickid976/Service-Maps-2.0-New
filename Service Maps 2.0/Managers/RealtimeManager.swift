//
//  RealtimeManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/23/24.
//

import Foundation
import SwiftUI
import Ably

let ABLY_KEY_SUBSCRIBE_ONLY = "DsHCCQ.qNceOA:3V_gM3AwmdS0M6zpHSRSxVSGV9HqyK6CpvvC8LB3KeQ"

@MainActor
class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()
    
    @ObservedObject private var dataStorageProvider = StorageManager.shared
    @ObservedObject private var authorizationProvider = AuthorizationProvider.shared
    @ObservedObject private var grdbManager = GRDBManager.shared
    private var channel: ARTRealtimeChannel?
    private var ably: ARTRealtime?
    @Published var lastMessage: Date?
    private var isSubscribed = false
    
    init() {}
    
    func initAblyConnection() async throws {
        // If we're already connected, unsubscribe first
        if channel != nil {
            await unsubscribeToChanges()
        }
        
        let congregationId: String?
        
        if let authCongregationId = authorizationProvider.congregationId.flatMap({ String($0) }) {
            congregationId = await (authCongregationId == "0") ? grdbManager.fetchFirstTerritory()?.congregation : authCongregationId
        } else {
            congregationId = await grdbManager.fetchFirstTerritory()?.congregation
        }
        
        guard let validCongregationId = congregationId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No congregation ID found"])
        }
        
        self.ably = ARTRealtime(key: ABLY_KEY_SUBSCRIBE_ONLY)
        self.channel = self.ably?.channels.get(validCongregationId)
    }

    func subscribeToChanges(completion: @escaping (Result<Bool, Error>) -> Void) async {
        await MainActor.run {
            guard let channel = self.channel else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Channel not initialized"])))
                return
            }

            channel.subscribe { [weak self] message in
                guard let self = self else { return }
                
                Task {
                    do {
                        try await Task.sleep(for: .seconds(1))
                        try await self.processMessage(message)
                        await MainActor.run {
                            self.lastMessage = Date()
                            self.isSubscribed = true
                        }
                        completion(.success(true))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func unsubscribeToChanges() async {
        guard let channel = channel else {
            print("No active channel to unsubscribe.")
            return
        }

        await MainActor.run {
            channel.unsubscribe()
            print("Unsubscribed from channel: \(channel.name)")
        }

        // Clear channel and Ably state
        self.channel = nil
        ably = nil
        isSubscribed = false
        print("Cleared Ably connection and subscription state.")
    }
    
    // Check subscription status
    var isCurrentlySubscribed: Bool {
        isSubscribed && channel != nil
    }
    
    @BackgroundActor
    private func processMessage(_ message: ARTMessage) async throws {
        switch message.name {
        case "visit":
            try await doVisit(message)
            //print("Test")
        case "call":
            try await doCall(message)
            //print("Test")
        default:
            break
        }
    }
    
    @BackgroundActor
    private func doVisit(_ message: ARTMessage) async throws {
        guard let dataString = message.data as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Message data is not in expected format"])
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(UserWithDataResponse.self, from: Data(dataString.utf8))
        var visit = try decoder.decode(Visit.self, from: Data(response.data.utf8))
        visit.id = "\(visit.house)-\(visit.date)"
        
        let userWithVisit = UserWithVisit(email: response.email, visit: visit)
        var visitToSave = visit
        
        if await self.dataStorageProvider.userEmail == userWithVisit.email {
            visitToSave.user = await self.dataStorageProvider.userEmail ?? visit.user
        }
        
        await saveVisitToDatabase(visitToSave)
    }
    
    @BackgroundActor
    private func doCall(_ message: ARTMessage) async throws {
        guard let dataString = message.data as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Message data is not in expected format"])
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(UserWithDataResponse.self, from: Data(dataString.utf8))
        var call = try decoder.decode(PhoneCall.self, from: Data(response.data.utf8))
        call.id = "\(call.phonenumber)-\(call.date)"
        
        let userWithCall = UserWithCall(email: response.email, call: call)
        var callToSave = call
        
        if await self.dataStorageProvider.userEmail == userWithCall.email {
            callToSave.user = await self.dataStorageProvider.userEmail ?? call.user
        }
        
        await saveCallToDatabase(callToSave)
    }

    @BackgroundActor
    private func saveVisitToDatabase(_ visit: Visit) async {
        do {
            let exists = try await grdbManager.dbPool.read { db in
                try Visit.fetchOne(db, key: visit.id) != nil
            }
            
            if exists {
                _ = await grdbManager.edit(visit)
            } else {
                _ = await grdbManager.add(visit)
            }
        } catch {
            print("Error saving visit to database: \(error)")
        }
    }
    
    @BackgroundActor
    private func saveCallToDatabase(_ call: PhoneCall) async {
        do {
            let exists = try await grdbManager.dbPool.read { db in
                try PhoneCall.fetchOne(db, key: call.id) != nil
            }
            
            if exists {
                _ = await grdbManager.edit(call)
            } else {
                _ = await grdbManager.add(call)
            }
        } catch {
            print("Error saving phone call to database: \(error)")
        }
    }
}

struct UserWithDataResponse: Codable {
    let email: String
    let data: String
}

struct UserWithVisit: Codable {
    let email: String
    let visit: Visit
}

struct UserWithCall: Codable {
    let email: String
    let call: PhoneCall
}
