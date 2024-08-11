//
//  HouseCell.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 9/5/23.
//

import SwiftUI
import NukeUI
import Combine

struct HouseCell: View {
    @ObservedObject var visitViewModel: VisitsViewModel
    @StateObject var realtimeManager = RealtimeManager.shared
    @State var house: HouseData
    var mainWindowSize: CGSize
    
    init(house: HouseData, mainWindowSize: CGSize) {
        self._visitViewModel = ObservedObject(initialValue: VisitsViewModel(house: house.house))
        self.house = house
        self.mainWindowSize = mainWindowSize
    }
    
    @State private var cancellable: AnyCancellable?
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                // House Number
                HStack {
                    Text("\(house.house.number)")
                        .font(.title2)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.heavy)
                        .hSpacing(.leading)
                        .padding(.leading, 5)
                    
                    // Symbol
                    Text("\(NSLocalizedString(house.visit?.symbol.localizedUppercase ?? "-", comment: ""))")
                        .font(.title3)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                        .hSpacing(.trailing)
                        .padding(.trailing, 5)
                }
                if let visit = house.visit {
                    let visitDateAsDate = Date(timeIntervalSince1970: Double(visit.date) / 1000)
                            let days = daysSince(date: visitDateAsDate)
                    // Date
                    VStack {
                            Text("\(formattedDate(date: visitDateAsDate)) \(days > 2 ? " (\(days) days ago)" : "")")
                                .font(.footnote)
                                .lineLimit(2)
                                .foregroundColor(Color.secondaryLabel)
                                .fontWeight(.bold)
                                .hSpacing(.leading)
                                .padding(.leading, 5)
                        // Notes
                        Text("\(visit.notes)")
                            .font(.body)
                            .lineLimit(4)
                            .foregroundColor(.secondaryLabel)
                            .fontWeight(.bold)
                            .padding(.leading, 5)
                            .multilineTextAlignment(.leading)
                            .hSpacing(.leading)
                    }.hSpacing(.leading).padding(10).background(Color.gray.opacity(0.2)) // Subtle background color
                        .cornerRadius(16)
                } else {
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
                            
                    }.hSpacing(.leading).padding(.leading, 5).padding(10).background(Color.gray.opacity(0.2)) // Subtle background color
                        .cornerRadius(16)
                        
                }
                
            }.vSpacing(.top)
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .frame(minWidth: mainWindowSize.width * 0.95)
        .optionalViewModifier { content in
            if isIpad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
        
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: realtimeManager.lastMessage) { value in
            if value != nil {
                visitViewModel.getVisits()
            }
            
        }
        .onAppear {
                visitViewModel.getVisits()
                    cancellable = visitViewModel.latestVisitUpdatePublisher
                        .subscribe(on: DispatchQueue.main)
                        .sink { newVisit in
                            // Check if the update is for the correct house and if it's a new/different visit
                            if let newVisit = newVisit, newVisit.house == house.house.id, newVisit != house.visit {
                                house.visit = newVisit  // Update the state with the new visit
                            } else if newVisit == nil{
                                house.visit = nil
                            }
                        }
                }
                .onDisappear {
                    cancellable?.cancel()
                }
    }
        
}
