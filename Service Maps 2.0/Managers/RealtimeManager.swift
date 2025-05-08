//
//  RealtimeManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/23/24.
//

import Foundation
import SwiftUI
import Ably

//MARK: - Ably Keys
let ABLY_KEY_SUBSCRIBE_ONLY = "DsHCCQ.qNceOA:3V_gM3AwmdS0M6zpHSRSxVSGV9HqyK6CpvvC8LB3KeQ"

//MARK: - Realtime Manager

final class RealtimeManager: ObservableObject, @unchecked Sendable {
    //MARK: - Singleton
    static let shared = RealtimeManager()

    //MARK: - Dependencies
    //private let dataStorageProvider = StorageManager.shared
    //private let authorizationProvider = AuthorizationProvider.shared
    private let grdbManager = GRDBManager.shared

    //MARK: - Properties
    private var channel: ARTRealtimeChannel?
    private var ably: ARTRealtime?
    @MainActor @Published var lastMessage: Date?
    private var isSubscribed = false
    private var cachedCongregationId: String?

    init() {}

    //MARK: - Connection Management
    func initAblyConnection() async throws {
        if channel != nil {
            await unsubscribeToChanges()
        }

        if let existing = cachedCongregationId {
            setupAbly(with: existing)
            return
        }

        let authCongregationId: String? = await MainActor.run {
            AuthorizationProvider.shared.congregationId.flatMap { String($0) }
        }

        let congregationId: String?

        if let authId = authCongregationId {
            if authId == "0" {
                congregationId = await grdbManager.fetchFirstTerritory()?.congregation
            } else {
                congregationId = authId
            }
        } else {
            congregationId = await grdbManager.fetchFirstTerritory()?.congregation
        }

        guard let validCongregationId = congregationId else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No congregation ID found"])
        }

        cachedCongregationId = validCongregationId
        setupAbly(with: validCongregationId)
    }

    private func setupAbly(with congregationId: String) {
        self.ably = ARTRealtime(key: ABLY_KEY_SUBSCRIBE_ONLY)
        self.channel = self.ably?.channels.get(congregationId)
    }

    func subscribeToChanges(completion: @escaping @Sendable (Result<Bool, Error>) -> Void) async {
        guard let channel = await MainActor.run(body: { self.channel }) else {
            await MainActor.run {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Channel not initialized"])))
            }
            return
        }

        channel.subscribe { [weak self] message in
            guard let self else { return }

            let safeMessage = SafeMessage(
                name: message.name ?? "",
                data: message.data
            )

            Task.detached(priority: .userInitiated) { [completion] in
                let result: Result<Bool, Error>
                do {
                    try await self.processSafeMessage(safeMessage)
                    result = .success(true)
                } catch {
                    result = .failure(error)
                }

                await MainActor.run {
                    self.lastMessage = Date()
                    self.isSubscribed = true
                    completion(result)
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

        self.channel = nil
        ably = nil
        isSubscribed = false
        print("Cleared Ably connection and subscription state.")
    }

    var isCurrentlySubscribed: Bool {
        isSubscribed && channel != nil
    }

    //MARK: - Message Processing
    @BackgroundActor
    private func processSafeMessage(_ message: SafeMessage) async throws {
        switch message.name {
        case "visit":
            try await doVisit(message)
        case "call":
            try await doCall(message)
        default:
            break
        }
    }

    
//    @BackgroundActor
//    private func processMessage(_ message: ARTMessage) async throws {
//        switch message.name {
//        case "visit":
//            try await doVisit(message)
//        case "call":
//            try await doCall(message)
//        default:
//            break
//        }
//    }

    @BackgroundActor
    private func doVisit(_ message: SafeMessage) async throws {
        guard let dataString = message.data as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Message data is not in expected format"])
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(UserWithDataResponse.self, from: Data(dataString.utf8))

        guard let innerData = response.data.data(using: .utf8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data string conversion failed"])
        }

        var visit = try decoder.decode(Visit.self, from: innerData)
        visit.id = "\(visit.house)-\(visit.date)"

        let userEmail = await MainActor.run { StorageManager.shared.userEmail }
        if userEmail == response.email {
            visit.user = response.email
        }

        await saveVisitToDatabase(visit)
    }

    @BackgroundActor
    private func doCall(_ message: SafeMessage) async throws {
        guard let dataString = message.data as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Message data is not in expected format"])
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(UserWithDataResponse.self, from: Data(dataString.utf8))

        guard let innerData = response.data.data(using: .utf8) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data string conversion failed"])
        }

        var call = try decoder.decode(PhoneCall.self, from: innerData)
        call.id = "\(call.phonenumber)-\(call.date)"

        let userEmail = await MainActor.run { StorageManager.shared.userEmail }
        if userEmail == response.email {
            call.user = response.email
        }

        await saveCallToDatabase(call)
    }

    //MARK: - Database Operations
    @BackgroundActor
    private func saveVisitToDatabase(_ visit: Visit) async {
        do {
            let exists = try await grdbManager.dbPool.read { db in
                try Visit.fetchOne(db, key: visit.id) != nil
            }

            if exists {
                _ = await grdbManager.editAsync(visit)
            } else {
                _ = await grdbManager.addAsync(visit)
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
                _ = await grdbManager.editAsync(call)
            } else {
                _ = await grdbManager.addAsync(call)
            }
        } catch {
            print("Error saving phone call to database: \(error)")
        }
    }
}

//MARK: - Models
struct UserWithDataResponse: Codable {
    let email: String
    let data: String
}

struct SafeMessage: @unchecked Sendable {
    let name: String
    let data: Any?
}
