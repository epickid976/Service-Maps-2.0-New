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
    @ObservedObject private var grdbManager = GRDBManager.shared // GRDB Manager instead of RealmManager
    private var channel: ARTRealtimeChannel?
    private var ably: ARTRealtime?
    @Published var lastMessage: Date?
    
    init() {
        Task {
            do {
                try await self.initAblyConnection()
                print("Ably connection initialized")
                self.subscribeToChanges {
                    switch $0 {
                    case .success:
                        print("Subscribed to changes")
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    func initAblyConnection() async throws {
        let congregationId: String?
        
        if let authCongregationId = authorizationProvider.congregationId.flatMap({ String($0) }) {
            congregationId = (authCongregationId == "0") ? grdbManager.fetchFirstTerritory()?.congregation : authCongregationId
        } else {
            congregationId = grdbManager.fetchFirstTerritory()?.congregation
        }
        
        if let validCongregationId = congregationId {
            self.ably = ARTRealtime(key: ABLY_KEY_SUBSCRIBE_ONLY)
            self.channel = self.ably?.channels.get(validCongregationId)
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No congregation ID found"])
        }
    }

    func subscribeToChanges(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let channel = self.channel else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Channel not initialized"])))
            return
        }

        channel.subscribe { [weak self] message in
            Task {
                do {
                    try await self?.processMessage(message)
                    await MainActor.run {
                        self?.lastMessage = Date()
                        completion(.success(true))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func unsubscribeToChanges() {
        channel?.unsubscribe()
    }

    private func processMessage(_ message: ARTMessage) async throws {
        switch message.name {
        case "visit":
            try await self.doVisit(message)
        case "call":
            try await self.doCall(message)
        default:
            break
        }
    }

    private func doVisit(_ message: ARTMessage) async throws {
        guard let dataString = message.data as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Message data is not in expected format"])
        }

        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(UserWithDataResponse.self, from: Data(dataString.utf8))
            
            var visit = try decoder.decode(Visit.self, from: Data(response.data.utf8)) // Use Visit struct
            visit.id = "\(visit.house)-\(visit.date)"
            
            let userWithVisit = UserWithVisit(email: response.email, visit: visit)
            
            var visitToSave = visit
            if self.dataStorageProvider.userEmail == userWithVisit.email {
                visitToSave.user = self.dataStorageProvider.userEmail ?? visit.user
            }
            print("Visit to save: \(visitToSave)")
            await saveVisitToDatabase(visitToSave)
        } catch {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode message data: \(error.localizedDescription)"])
        }
    }

    private func doCall(_ message: ARTMessage) async throws {
        guard let dataString = message.data as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Message data is not in expected format"])
        }
        
        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(UserWithDataResponse.self, from: Data(dataString.utf8))
            
            var call = try decoder.decode(PhoneCall.self, from: Data(response.data.utf8)) // Use PhoneCall struct
            call.id = "\(call.phonenumber)-\(call.date)"
            
            let userWithCall = UserWithCall(email: response.email, call: call)
            
            var callToSave = call
            if self.dataStorageProvider.userEmail == userWithCall.email {
                callToSave.user = self.dataStorageProvider.userEmail ?? call.user
            }
            
            await saveCallToDatabase(callToSave)
        } catch {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode message data: \(error.localizedDescription)"])
        }
    }

    // Save Visit to GRDB
    private func saveVisitToDatabase(_ visit: Visit) async {
        do {
            // Perform the synchronous database operation
            let exists = try await grdbManager.dbPool.read { db in
                try Visit.fetchOne(db, key: visit.id) != nil
            }

            if exists {
                // Update the visit directly (if edit doesn't throw, no need for try?)
                _ = grdbManager.edit(visit)
            } else {
                // Insert new visit
                _ = grdbManager.add(visit)
            }
        } catch {
            print("Error saving visit to database: \(error)")
        }
    }

    private func saveCallToDatabase(_ call: PhoneCall) async {
        do {
            // Perform the synchronous database operation
            let exists = try await grdbManager.dbPool.read { db in
                try PhoneCall.fetchOne(db, key: call.id) != nil
            }

            if exists {
                // Update the phone call directly
                _ = grdbManager.edit(call)
            } else {
                // Insert new phone call
                _ = grdbManager.add(call)
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
