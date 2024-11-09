//
//  HapticManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/20/24.
//

import UIKit // Or SwiftUI, depending on your project
import SwiftUI

@MainActor
class HapticManager {
    // Feedback Generators
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // Custom Feedback Patterns (iOS 13+)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let softNotification = UINotificationFeedbackGenerator()

    static let shared = HapticManager()
    
    private init() {
            // Prepare the generators when the shared instance is created
            impactGenerator.prepare()
            notificationGenerator.prepare()
            selectionGenerator.prepare()
            lightImpact.prepare()
            rigidImpact.prepare()
            softNotification.prepare()
        }
    
    // MARK: - Public Interface
    func trigger(_ type: HapticType) {
        if !preferencesViewModel.hapticFeedback {
            return
        }
        switch type {
        case .impact:
            impactGenerator.impactOccurred()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .selectionChanged:
            selectionGenerator.selectionChanged()

        // iOS 13+ Specific
        case .lightImpact:
            lightImpact.impactOccurred()
        case .rigidImpact:
            rigidImpact.impactOccurred()
        case .softSuccess:
            softNotification.notificationOccurred(.success)
        case .softError:
            softNotification.notificationOccurred(.error)
        case .softWarning:
            softNotification.notificationOccurred(.warning)
        }
    }
}

// Haptic Types Enum
enum HapticType {
    case impact, success, error, warning, selectionChanged

    // iOS 13+
    case lightImpact, rigidImpact
    case softSuccess, softError, softWarning
}


@MainActor
extension NavigationLink {
    func onTapHaptic(_ type: HapticType) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.trigger(type)
        })
    }
}


class NavigationHistoryManager: ObservableObject {
    @Published var history: [ViewName] = []

    func append(view: ViewName) {
        history.append(view)
    }

    func removeLast() {
        history.removeLast()
    }

    func remove(to view: ViewName) {
        if let index = history.firstIndex(of: view) {
            history = Array(history.prefix(upTo: index + 1))
        }
    }
}

enum ViewName: String {
    case territories = "Territories"
    case addresses = "Addresses"
    case houses = "Houses"
    case visits = "Visits"
}

struct CustomNavigationBackButton: View {
    @EnvironmentObject var navigationHistoryManager: NavigationHistoryManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Menu {
            ForEach(navigationHistoryManager.history, id: \.self) { view in
                Button(action: {
                    navigationHistoryManager.remove(to: view)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(view.rawValue)
                }
            }
        } label: {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
        .padding()
    }
}
