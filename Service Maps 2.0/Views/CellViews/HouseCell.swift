//
//  HouseCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import SwiftUI
import NukeUI
import Combine

//MARK: - House Cell

struct HouseCell: View {
    @State var revisitView: Bool = false
    @StateObject private var visitViewModel: VisitsViewModel
    @State private var house: HouseData
    @State private var cancellable: AnyCancellable?
    
    
    var mainWindowSize: CGSize
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    init(revisitView: Bool = false , house: HouseData, mainWindowSize: CGSize) {
        _visitViewModel = StateObject(wrappedValue: VisitsViewModel(house: house.house, revisitView: revisitView))
        _house = State(initialValue: house)
        self.mainWindowSize = mainWindowSize
        _revisitView = State(initialValue: revisitView)
    }
    
    //MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                headerView
                
                if let visit = house.visit {
                    visitDetailView(for: visit)
                } else {
                    noNotesView
                }
                
            }.vSpacing(.top)
                .frame(maxWidth: .infinity)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .optionalViewModifier { content in
            if isIpad {
                content.frame(maxHeight: .infinity)
            } else {
                content
            }
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear(perform: onAppear)
        //.onChange(of: RealtimeManager.shared.lastMessage, perform: onMessageChange)
        .onDisappear(perform: onDisappear)
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        HStack {
            Text("\(house.house.number)")
                .font(.title2)
                .lineLimit(2)
                .foregroundColor(.primary)
                .fontWeight(.heavy)
                .hSpacing(.leading)
                .padding(.leading, 5)
            
            Text("\(NSLocalizedString(house.visit?.symbol.localizedUppercase ?? "-", comment: ""))")
                .font(.title3)
                .lineLimit(2)
                .foregroundColor(.primary)
                .fontWeight(.bold)
                .hSpacing(.trailing)
                .padding(.trailing, 5)
        }
    }
    
    private func visitDetailView(for visit: Visit) -> some View {
        let visitDateAsDate = Date(timeIntervalSince1970: Double(visit.date) / 1000)
        let days = daysSince(date: visitDateAsDate)
        
        return VStack {
            let daysAgoString = days > 2 ? String(format: NSLocalizedString("(%d days ago)", comment: ""), days) : ""
            
            Text("\(formattedDate(date: visitDateAsDate)) \(daysAgoString)")
                .font(.footnote)
                .lineLimit(2)
                .foregroundColor(Color.secondaryLabel)
                .fontWeight(.bold)
                .hSpacing(.leading)
                .padding(.leading, 5)
                .transition(.opacity)
                .animation(.spring(), value: visit)
            
            Text("\(visit.notes)")
                .font(.body)
                .lineLimit(8)
                .foregroundColor(.secondaryLabel)
                .fontWeight(.bold)
                .padding(.leading, 5)
                .multilineTextAlignment(.leading)
                .hSpacing(.leading)
                .transition(.opacity)
                .animation(.spring(), value: visit.notes)
        }
        .hSpacing(.leading)
        .padding(10)
        .background(Color.gray.opacity(0.2)) // Subtle background color
        .cornerRadius(16)
    }
    
    private var noNotesView: some View {
        HStack {
            Image(systemName: "text.word.spacing")
                .resizable()
                .imageScale(.medium)
                .foregroundColor(.secondaryLabel)
                .frame(width: 20, height: 20)
            
            Text(NSLocalizedString("No notes available.", comment: ""))
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.secondaryLabel)
                .fontWeight(.bold)
        }
        .hSpacing(.leading)
        .padding(.leading, 5)
        .padding(10)
        .background(Color.gray.opacity(0.2)) // Subtle background color
        .cornerRadius(16)
    }
    
    // MARK: - Lifecycle Methods
    private func onAppear() {
        visitViewModel.getVisits(revisitView: revisitView)
        
        cancellable = visitViewModel.latestVisitUpdatePublisher
            .subscribe(on: DispatchQueue.main)
            .sink { newVisit in
                // Check if the update is for the correct house and if it's a new/different visit
                if let newVisit = newVisit, newVisit.house == house.house.id, newVisit != house.visit {
                    house.visit = newVisit  // Update the state with the new visit
                } else if newVisit == nil {
                    house.visit = nil
                }
            }
    }
    
    private func onMessageChange(_ value: Date?) {
        if value != nil {
            visitViewModel.getVisits(revisitView: revisitView)
        }
    }
    
    private func onDisappear() {
        cancellable?.cancel()
    }
}
