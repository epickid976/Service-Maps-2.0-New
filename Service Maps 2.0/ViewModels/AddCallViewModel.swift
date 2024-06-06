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
    
    init(phoneNumber: PhoneNumberModel) {
        error = ""
        self.phoneNumber = phoneNumber
    }
    
    @Published var notes = ""

    @Published private var dataUploader = DataUploaderManager()
    
    @Published var phoneNumber: PhoneNumberModel
    
    @Published var error = ""
    
    @Published var loading = false
    
    func addCall() async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let callObject = PhoneCallObject()
        callObject.id = "\(phoneNumber.id)-\(Date.now.millisecondsSince1970)"
        callObject.phoneNumber = phoneNumber.id
        callObject.date = (Date.now.millisecondsSince1970)
        callObject.notes = notes
        callObject.user = StorageManager.shared.userName ?? ""
        return await dataUploader.addCall(call: callObject)
    }
    
    func editCall(call: PhoneCallModel) async -> Result<Bool, Error> {
        withAnimation {
            loading = true
        }
        let callObject = PhoneCallObject()
        callObject.id = call.id
        callObject.phoneNumber = call.phonenumber
        callObject.date = call.date
        callObject.notes = notes
        callObject.user = StorageManager.shared.userName ?? ""
        return await dataUploader.updateCall(call: callObject)
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
