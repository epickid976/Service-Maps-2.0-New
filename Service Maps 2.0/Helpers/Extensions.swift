//
//  Extensions.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/25/24.
//

import Foundation
import SwiftUI
import NavigationTransitions

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

extension Array {
    mutating func filterInPlace(isIncluded: (Element) throws -> Bool) rethrows {
        var writeIndex = self.startIndex
        for readIndex in self.indices {
            let element = self[readIndex]
            let include = try isIncluded(element)
            if include {
                if writeIndex != readIndex {
                    self[writeIndex] = element
                }
                writeIndex = self.index(after: writeIndex)
            }
        }
        self.removeLast(self.distance(from: writeIndex, to: self.endIndex))
    }
}

extension Array {
    mutating func removeInPlace(where shouldRemove: (Element) throws -> Bool) rethrows {
        var writeIndex = self.startIndex
        for readIndex in self.indices {
            let element = self[readIndex]
            if try shouldRemove(element) {
                continue // Skip elements we want to remove
            }
            // If we're not removing, move the element to the write position
            if writeIndex != readIndex {
                self[writeIndex] = element
            }
            writeIndex = self.index(after: writeIndex)
        }
        
        // Remove the tail elements that we've skipped over
        removeLast(self.distance(from: writeIndex, to: self.endIndex))
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

extension String {
  func removeFormatting() -> String {
    return replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
  }
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

func isInLastTwoWeeks(_ visitDate: Date) -> Bool {
  let today = Date()
  let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: today)!
  return twoWeeksAgo <= visitDate && visitDate <= today
}

func areEqual(tokenModel: MyTokenModel, tokenObject: TokenObject) -> Bool {
  return tokenModel.id == tokenObject.id &&
         tokenModel.name == tokenObject.name &&
         tokenModel.owner == tokenObject.owner &&
         tokenModel.congregation == tokenObject.congregation &&
         tokenModel.moderator == tokenObject.moderator &&
         tokenModel.expire == tokenObject.expire &&
         tokenModel.user == tokenObject.user
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension AnyNavigationTransition {
    static var zoom: Self {
        .init(Zoom())
    }
}

struct Zoom: NavigationTransition {
    var body: some NavigationTransition {
        MirrorPush {
            Scale(0.5)
            OnInsertion {
                ZPosition(1)
                Opacity()
            }
        }
    }
}

@MainActor
func formattedDate(date: Date, withTime: Bool = true) -> String {
    let formatter1 = DateFormatter()
    
    if withTime {
        if  Calendar.current.isDateInToday(date) {
            formatter1.dateFormat = "HH:mm a"
            return NSLocalizedString("Today ", comment: "") + formatter1.string(from: date)
        } else if Calendar.current.isDateInYesterday(date){
            formatter1.dateFormat = "HH:mm a"
            return NSLocalizedString("Yesterday ", comment: "") + formatter1.string(from: date)
        } else if Calendar.current.isDateInThisWeek(date) {
            formatter1.dateFormat = "EEEE HH:mm a"
            return  formatter1.string(from: date)
        } else {
            formatter1.dateFormat = "dd MMM yyyy hh:mm a"
            return  formatter1.string(from: date)
        }
    } else {
        if  Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date){
            return "Yesterday"
        } else if Calendar.current.isDateInThisWeek(date) {
            formatter1.dateFormat = "EEEE"
            return  formatter1.string(from: date)
        } else {
            formatter1.dateFormat = "MM-dd-yyyy"
            return  formatter1.string(from: date)
        }
    }
}

extension Calendar {
    private var currentDate: Date { return Date() }
    
    func isDateInThisWeek(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .weekOfYear)
    }
    
    func isDateInThisMonth(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .month)
    }
    
    func isDateInThisYear(_ date: Date) -> Bool {
        return isDate(date, equalTo: currentDate, toGranularity: .year)
    }
    
    func isDateInNextWeek(_ date: Date) -> Bool {
        guard let nextWeek = self.date(byAdding: DateComponents(weekOfYear: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextWeek, toGranularity: .weekOfYear)
    }
    
    func isDateInNextMonth(_ date: Date) -> Bool {
        guard let nextMonth = self.date(byAdding: DateComponents(month: 1), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: nextMonth, toGranularity: .month)
    }
    
    func isDateInFollowingMonth(_ date: Date) -> Bool {
        guard let followingMonth = self.date(byAdding: DateComponents(month: 2), to: currentDate) else {
            return false
        }
        return isDate(date, equalTo: followingMonth, toGranularity: .month)
    }
}

extension Date {
    var millisecondsSince1970:Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension String {
    func fixToBrowserString() -> String {
        self.replacingOccurrences(of: ";", with: "%3B")
            .replacingOccurrences(of: "\n", with: "%0D%0A")
            .replacingOccurrences(of: "!", with: "%21")
            .replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\\", with: "%5C")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "‘", with: "%91")
            .replacingOccurrences(of: ",", with: "%2C")
            //more symbols fixes here: https://mykindred.com/htmlspecialchars.php
    }
}

func openMail(emailTo:String, subject: String, body: String) {
    if let url = URL(string: "mailto:\(emailTo)?subject=\(subject.fixToBrowserString())&body=\(body.fixToBrowserString())"),
       UIApplication.shared.canOpenURL(url)
    {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension Result where Success == Bool {
    func onSuccess(_ action: () -> Void) -> Result {
        if case .success(true) = self {
            action()
        }
        return self
    }
}

func openMaps(searchQuery: String) {
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encodedQuery)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
    }
