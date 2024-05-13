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
  let today = Calendar.current.startOfDay(for: Date())
  let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -30, to: today)!
  return twoWeeksAgo <= visitDate && visitDate <= today
}
