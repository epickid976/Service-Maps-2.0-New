//
//  AreEqualFuncs.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 4/15/24.
//

import Foundation

func areEqual(tokenModel: MyTokenModel, tokenObject: TokenObject) -> Bool {
  return tokenModel.id == tokenObject.id &&
         tokenModel.name == tokenObject.name &&
         tokenModel.owner == tokenObject.owner &&
         tokenModel.congregation == tokenObject.congregation &&
         tokenModel.moderator == tokenObject.moderator &&
         tokenModel.expire == tokenObject.expire &&
         tokenModel.user == tokenObject.user
}

extension String {
    func formatPhoneNumber() -> String {
        let cleanNumber = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        let mask = "(XXX) XXX-XXXX"
        
        var result = ""
        var startIndex = cleanNumber.startIndex
        var endIndex = cleanNumber.endIndex
        
        for char in mask where startIndex < endIndex {
            if char == "X" {
                result.append(cleanNumber[startIndex])
                startIndex = cleanNumber.index(after: startIndex)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
}

extension String {
  func removeFormatting() -> String {
    return replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
  }
}

extension String {
    func isValidPhoneNumber() -> Bool {
        // Use a regular expression to match a valid phone number format
        let phoneRegex = "^\\(\\d{3}\\) \\d{3}-\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: self)
    }
}




func isInLastTwoWeeks(_ visitDate: Date) -> Bool {
  let today = Date()
  let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: today)!
  return twoWeeksAgo <= visitDate && visitDate <= today
}
extension Result where Success == Bool {

    @discardableResult
    func onSuccess(_ closure: (Bool) throws -> Success) rethrows -> Success? {
        switch self {
        case .success(let value):
            return try closure(value) // Execute closure with the boolean value
        case .failure:
            return nil // Do nothing on failure
        }
    }

    func onFailure(_ closure: (Error) -> Void) {
        switch self {
        case .success:
            break // Do nothing on success
        case .failure(let error):
            closure(error) // Execute closure with the error
        }
    }
}
