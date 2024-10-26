//
//  AddCallViewModel.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 5/1/24.
//

import Foundation
import SwiftUI

@MainActor
class AddCallViewModel: ObservableObject {
    
    init(phoneNumber: PhoneNumber) {
        error = ""
        self.phoneNumber = phoneNumber
    }
    
    @Published var notes = ""

    @Published private var dataUploader = DataUploaderManager()
    
    @Published var phoneNumber: PhoneNumber
    
    @Published var error = ""
    
    @Published var loading = false
    
    func addCall() async -> Result<Void, Error> {
        withAnimation {
            loading = true
        }
        let callObject = PhoneCall(id: "\(phoneNumber.id)-\(Date.now.millisecondsSince1970)", phonenumber: phoneNumber.id, date: (Date.now.millisecondsSince1970), notes: notes, user: StorageManager.shared.userName ?? "")
        return await dataUploader.addPhoneCall(phoneCall: callObject)
    }
    
    func editCall(call: PhoneCall) async -> Result<Void, Error> {
        withAnimation {
            loading = true
        }
        let callObject = PhoneCall(id: call.id, phonenumber: call.phonenumber, date: call.date, notes: notes, user: StorageManager.shared.userName ?? "")
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
}
