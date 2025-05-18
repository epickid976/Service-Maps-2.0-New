//
//  CirlceButtonStyle.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import Foundation
import SwiftUI
import Combine

//MARK: - Circle Button Style
struct CircleButtonStyle: ButtonStyle {
    var imageName: String
    var foreground = Color.primary
    var background = Color.white
    var width: CGFloat = 40
    var height: CGFloat = 40
    @Binding var progress: CGFloat
    @Binding var animation: Bool

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .optionalViewModifier { content in
                    if progress > 0.01 {
                        content.fill(Color.clear)
                    } else {
                        content.fill(Material.ultraThin)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

            Image(systemName: imageName == "magnifyingglass" && animation ? "" : imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(foreground)
                .padding(12)
                .bold()
                .optionalViewModifier { content in
                    if #available(iOS 17, *) {
                        content.symbolEffect(.bounce, options: .speed(3.0), value: animation)
                    } else {
                        content
                    }
                }
        }
        .frame(width: width, height: height)
    }
}

//MARK: - Pill Button Style
@MainActor
struct PillButtonStyle: ButtonStyle {
    // MARK: - Properties
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
    
    // MARK: - Body
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                .optionalViewModifier { content in
                    if progress > 0.01 {
                        content.fill(Color.clear)
                    } else {
                        content.fill(Material.ultraThin)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: height / 2)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

            VStack(spacing: 2) {
                if synced {
                    displayText(NSLocalizedString("Last Synced", comment: ""), fontWeight: .bold, fontSize: .caption, foregroundColor: foreground)
                    displayText(timePassed, fontWeight: .bold, fontSize: .caption2, foregroundColor: foreground)
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
        }
        .frame(width: width, height: height)
        .padding(5)
        .onAppear { updateElapsedTime() }
        .onChange(of: synced) { newValue in
            if newValue {
                updateElapsedTime(instant: true)
            }
        }
        .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in updateElapsedTime() }
    }

    // MARK: - Functions
    func updateElapsedTime(instant: Bool = false) {
        timePassed = instant
            ? NSLocalizedString("Now", comment: "")
            : getFormattedElapsedTime(from: lastTime)
    }

    func displayText(
        _ text: String,
        fontWeight: Font.Weight = .bold,
        fontSize: Font = .caption,
        foregroundColor: Color
    ) -> some View {
        Text(text)
            .fontWeight(fontWeight)
            .font(fontSize)
            .foregroundColor(foregroundColor)
            .multilineTextAlignment(.center)
    }
}

//MARK: - Get time
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

func isMoreThanFiveMinutesOld(date: Date?) async -> Bool {
    guard let date = date else { return true }
    let calendar = Calendar.current
    let fiveMinutesAgo = calendar.date(byAdding: .minute, value: -5, to: Date())!
    return date < fiveMinutesAgo
}

struct GlassStepper: View {
    @Binding var value: Int
    var minValue: Int = 0
    var maxValue: Int = 999
    var cornerRadius: CGFloat = 16
    var buttonSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                HapticManager.shared.trigger(.softError)
                if value > minValue { value -= 1 }
            }) {
                Image(systemName: "minus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.primary)
                    .padding(10)
            }
            .background(Material.ultraThin)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.6))
            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
            
            Button(action: {
                HapticManager.shared.trigger(.lightImpact)
                if value < maxValue { value += 1 }
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.primary)
                    .padding(10)
            }
            .background(Material.ultraThin)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.6))
            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Material.ultraThin)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
