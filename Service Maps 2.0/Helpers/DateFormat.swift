//
//  DateFormat.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import Foundation

@MainActor
func formattedDate(date: Date, withTime: Bool = true) -> String {
    let formatter1 = DateFormatter()
    
    if withTime {
        if  Calendar.current.isDateInToday(date) {
            formatter1.dateFormat = "HH:mm"
            return NSLocalizedString("Today ", comment: "") + formatter1.string(from: date)
        } else if Calendar.current.isDateInYesterday(date){
            formatter1.dateFormat = "HH:mm"
            return NSLocalizedString("Yesterday ", comment: "") + formatter1.string(from: date)
        } else if Calendar.current.isDateInThisWeek(date) {
            formatter1.dateFormat = "EEEE HH:mm"
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
