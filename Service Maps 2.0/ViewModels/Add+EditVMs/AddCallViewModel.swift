//
//  AddCallViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import Foundation
import SwiftUI

// MARK: - Add Call View Model

@MainActor
class AddCallViewModel: ObservableObject {
    
    // MARK: - Initializers
    init(phoneNumber: PhoneNumber) {
        error = ""
        self.phoneNumber = phoneNumber
    }
    
    // MARK: - Dependencies
    @Published private var dataUploader = DataUploaderManager()
    
    // MARK: - Properties
    @Published var notes = ""

    @Published var phoneNumber: PhoneNumber
    
    @Published var error = ""
    
    @Published var loading = false
    
    // MARK: - Functions
    @BackgroundActor
    func addCall() async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation {
                loading = true
            }
        }
        let date = Date.now.millisecondsSince1970
        let callObject = await PhoneCall(id: "\(phoneNumber.id)-\(date)", phonenumber: phoneNumber.id, date: (date), notes: notes, user: StorageManager.shared.userEmail ?? "")
        return await dataUploader.addPhoneCall(phoneCall: callObject)
    }
    
    @BackgroundActor
    func editCall(call: PhoneCall) async -> Result<Void, Error> {
        await MainActor.run {
            withAnimation {
                loading = true
            }
        }
        let callObject = await PhoneCall(id: call.id, phonenumber: call.phonenumber, date: call.date, notes: notes, user: StorageManager.shared.userEmail ?? "")
        return await dataUploader.updatePhoneCall(phoneCall: callObject)
    }
    
    func checkInfo() -> Bool {
        if notes.isEmpty {
            error = NSLocalizedString("Notes are required.", comment: "")
            return false
        } else {
            return true
        }
    }
    
    func fillWithLastCall() async {
        if let lastCall = await fetchLastCall() {
           await MainActor.run {
               withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                   self.notes = lastCall.notes
               }
           }
       } else {
           withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
               self.error = NSLocalizedString("No previous call found.", comment: "")
           }
       }
    }
    
    private func fetchLastCall() async -> PhoneCall? {
        // Fetch your last visit from your data source
        return GRDBManager.shared.getLastCallForNumber(phoneNumber)
    }
}
