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
    //@Binding var text: String
    
    @State var timePassed = getElapsedMinutes()
    
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
                        if isMoreThanAMinuteOld(date: lastTime) {
                            displayText(NSLocalizedString("Last Synced", comment: ""), fontWeight: .bold, fontSize: .caption, foregroundColor: foreground)
                            displayText(NSLocalizedString("\(getElapsedMinutes()) minute(s)", comment: ""), fontWeight: .bold, fontSize: .caption2, foregroundColor: foreground)
                        } else {
                            displayText(NSLocalizedString("Last Synced", comment: ""), fontWeight: .bold, fontSize: .caption, foregroundColor: foreground)
                            displayText(NSLocalizedString("Now", comment: ""), fontWeight: .bold, fontSize: .caption2, foregroundColor: foreground)
                        }
                    } else {
                        //displayText(NSLocalizedString("Syncing", comment: ""), fontWeight: .bold, fontSize: .caption, foregroundColor: foreground)
                        ProgressView()
                    }
                }.optionalViewModifier { content in
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
            .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
                timePassed = getElapsedMinutes()
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

func getElapsedMinutes() -> Int {
    guard let startTime = StorageManager.shared.lastTime else { return 0 } // Handle no start time
    let elapsedTime = floor(Date().timeIntervalSince(startTime) / 60.0)
    return Int(elapsedTime)
}

func isMoreThanAMinuteOld(date: Date?) -> Bool {
    guard let date = date else { return true }
    let calendar = Calendar.current
    let oneMinuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
    return date < oneMinuteAgo
}

