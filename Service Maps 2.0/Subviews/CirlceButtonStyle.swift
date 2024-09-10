//
//  CirlceButtonStyle.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import Foundation
import SwiftUI
import Combine

struct CircleButtonStyle: ButtonStyle {
    
    var imageName: String
    var foreground = Color.primary
    var background = Color.white
    var width: CGFloat = 40
    var height: CGFloat = 40
    @Binding var progress: CGFloat
    @Binding var animation: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        
        Circle()
            
            .optionalViewModifier { content in
                if progress > 0.01 {
                    content
                        .fill(Color.clear)
                } else {
                    content
                        .fill(Material.ultraThin)
                }
            }
        
            .overlay(Image(systemName: imageName == "magnifyingglass" && animation == true ? "" : imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(foreground)
                .padding(12)
                .bold()
                .optionalViewModifier { content in
                    if #available(iOS 17, *) {
                        content
                            .symbolEffect(.bounce, options: .speed(3.0), value: animation)
                    } else {
                        content
                    }
                }
            )
        
            .frame(width: width, height: height)
            
    }
}

struct PillButtonStyle: ButtonStyle {
    
    var imageName: String
    var foreground = Color.primary
    var background = Color.white
    var width: CGFloat = 100
    var height: CGFloat = 40
    @Binding var progress: CGFloat
    @Binding var animation: Bool
    @Binding var synced: Bool
    @Binding var lastTime: Date?
    
    @State private var timePassed = getFormattedElapsedTime(from: StorageManager.shared.lastTime)
    
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerSize: CGSize(width: 100.0, height: 100.0), style: .continuous)
            .optionalViewModifier { content in
                if progress > 0.01 {
                    content
                        .fill(Color.clear)
                } else {
                    content
                        .fill(Material.ultraThin)
                }
            }
            .overlay(
                VStack {
                    if synced {
                        displayText(NSLocalizedString("Last Synced", comment: ""), fontWeight: .bold, fontSize: .caption, foregroundColor: foreground)
                        displayText(NSLocalizedString("\(timePassed)", comment: ""), fontWeight: .bold, fontSize: .caption2, foregroundColor: foreground)
                    } else {
                        ProgressView()
                    }
                }
                .optionalViewModifier { content in
                    if #available(iOS 17, *) {
                        content
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.5), value: timePassed)
                            .animation(.spring(duration: 0.5), value: synced)
                    } else {
                        content
                    }
                }
                .animation(.easeInOut, value: synced)
            )
            .frame(width: width, height: height, alignment: .trailing)
            .animation(.spring(), value: synced)
            .padding(5)
            .onAppear {
                // When the view appears, calculate the time passed
                updateElapsedTime()
            }
            .onChange(of: synced) { _ in
                // Immediately update the time when synced becomes true
                if synced {
                    updateElapsedTime(instant: true) // Force an instant update to "Now"
                }
            }
            .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
                updateElapsedTime() // Update time passed every 5 seconds
            }
    }
    
    func updateElapsedTime(instant: Bool = false) {
        // If it's an instant update (sync just happened), force "Now"
        if instant {
            timePassed = NSLocalizedString("Now", comment: "Indicates that something just synced")
        } else {
            timePassed = getFormattedElapsedTime(from: lastTime)
        }
    }
    
    func displayText(_ text: String, fontWeight: Font.Weight = .bold, fontSize: Font = .caption, foregroundColor: Color) -> some View {
        Text(text)
            .fontWeight(fontWeight)
            .font(fontSize)
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(.center)
    }
}

// Updated function to calculate elapsed time from a passed Date value
func getFormattedElapsedTime(from lastTime: Date?) -> String {
    guard let startTime = lastTime else { return NSLocalizedString("Now", comment: "Indicates that no time has been recorded") }
    let elapsedTime = Date().timeIntervalSince(startTime)

    if elapsedTime < 60 {
        return NSLocalizedString("Now", comment: "Indicates that something happened less than a minute ago")
    } else if elapsedTime < 3600 {
        let minutes = Int(elapsedTime / 60)
        return String(format: NSLocalizedString("%d minute(s)", comment: "Indicates how many minutes have passed"), minutes)
    } else if elapsedTime < 86400 {
        let hours = Int(elapsedTime / 3600)
        return String(format: NSLocalizedString("%d hour(s)", comment: "Indicates how many hours have passed"), hours)
    } else {
        let days = Int(elapsedTime / 86400)
        return String(format: NSLocalizedString("%d day(s)", comment: "Indicates how many days have passed"), days)
    }
}

func isMoreThanAMinuteOld(date: Date?) -> Bool {
    guard let date = date else { return true }
    let calendar = Calendar.current
    let oneMinuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
    return date < oneMinuteAgo
}

func isMoreThanFiveMinutesOld(date: Date?) -> Bool {
    guard let date = date else { return true }
    let calendar = Calendar.current
    let fiveMinutesAgo = calendar.date(byAdding: .minute, value: -5, to: Date())!
    return date < fiveMinutesAgo
}
