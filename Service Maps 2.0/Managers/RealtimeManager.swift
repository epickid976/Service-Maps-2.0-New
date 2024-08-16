//
//  RealtimeManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/23/24.
//

import Foundation
import SwiftUI
import Ably
import RealmSwift

let ABLY_KEY_SUBSCRIBE_ONLY = "DsHCCQ.qNceOA:3V_gM3AwmdS0M6zpHSRSxVSGV9HqyK6CpvvC8LB3KeQ"


class RealtimeManager: ObservableObject {
    
    @ObservedObject private var dataStorageProvider = StorageManager.shared
    @ObservedObject private var authorizationProvider = AuthorizationProvider.shared
    @ObservedObject private var realmManager = RealmManager.shared
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
            congregationId = (authCongregationId == "0") ? self.realmManager.getAllTerritoriesDirect().first?.congregation : authCongregationId
        } else {
            congregationId = self.realmManager.getAllTerritoriesDirect().first?.congregation
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
                        await MainActor.run {  // Run completion on the main thread
                            self?.lastMessage = Date()
                            completion(.success(true))
                        }
                    } catch {
                        await MainActor.run {  // Run completion on the main thread
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
            
            var visit = try decoder.decode(VisitModel.self, from: Data(response.data.utf8))
            visit.id = "\(visit.house)-\(visit.date)"
            
            let userWithVisit = UserWithVisit(email: response.email, visit: visit)
            
            var visitToSave = visit
            if self.dataStorageProvider.userEmail == userWithVisit.email {
                visitToSave = visit.copy(user: self.dataStorageProvider.userEmail ?? visit.user)
            }
            print("Visit to save: \(visitToSave)")
            await saveVisitToRealm(visitToSave)
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
                
                var call = try decoder.decode(PhoneCallModel.self, from: Data(response.data.utf8))
                call.id = "\(call.phonenumber)-\(call.date)"
                
                let userWithCall = UserWithCall(email: response.email, call: call)
                
                var callToSave = call
                if self.dataStorageProvider.userEmail == userWithCall.email {
                    callToSave = call.copy(user: self.dataStorageProvider.userEmail ?? call.user)
                }
                
                await saveCallToRealm(callToSave)
            } catch {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode message data: \(error.localizedDescription)"])
            }
        }

    private func saveVisitToRealm(_ visit: VisitModel) async {
        await MainActor.run {
            if realmManager.realmDatabase.objects(VisitObject.self).filter("id == %d", visit.id).first != nil {
               _ = self.realmManager.updateVisit(visit: visit)
            } else {
              _ = realmManager.addModel(VisitObject().createVisitObject(from: visit))
            }
        }
    }

    private func saveCallToRealm(_ call: PhoneCallModel) async {
        await MainActor.run {
            if realmManager.realmDatabase.objects(PhoneCallObject.self).filter("id == %d", call.id).first != nil {
                _ = self.realmManager.updatePhoneCall(phoneCall: call)
            } else {
                _ = realmManager.addModel(PhoneCallObject().createTerritoryObject(from: call))
            }
        }
    }
    
    class var shared: RealtimeManager {
        struct Static {
            static let instance = RealtimeManager()
        }
        
        return Static.instance
    }
}

struct UserWithDataResponse: Codable {
    let email: String
    let data: String
}

struct UserWithVisit: Codable {
    let email: String
    let visit: VisitModel
}

struct UserWithCall: Codable {
    let email: String
    let call: PhoneCallModel
}

