//
//  CellView.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 8/5/23.
//
import SwiftUI
import CoreData
import NukeUI
import MijickPopups

//MARK: - Territory Cell

struct CellView: View {
    var territory: Territory
    var houseQuantity: Int
    var width: Double = 0.95
    let isIpad = UIDevice.current.userInterfaceIdiom == .pad
    var mainWindowSize: CGSize
    //@Binding var territoryModel: Territory
    
    @State private var cellHeight: CGFloat = 0
    
    var ipad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    //MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .teal]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ).opacity(0.6)
                        )
                    
                    VStack {
                        Text("\(territory.number)")
                            .font(.system(size:  25, weight: .heavy))
                            .foregroundColor(.white)
                        
                    }
                    .frame(minWidth: mainWindowSize.width * 0.20)
                }
                .hSpacing(.leading)
                .frame(width: mainWindowSize.width * 0.20, height: cellHeight, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(territory.description )
                    .font(.headline)
                    .lineLimit(5)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Text("Doors: \(houseQuantity)")
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.secondaryLabel)
                    .fontWeight(.bold)
            }.padding(10).vSpacing(.top)
                .frame(maxWidth: mainWindowSize.width * 0.8, alignment: .leading)
        }
        .id(territory.id)
        
        .frame(minWidth: isIpad ? (mainWindowSize.width * width ) / 2 : mainWindowSize.width * width)
        //.frame(minHeight: isIpad ? 100 : 20)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    self.cellHeight = geometry.size.height
                }
        })
        .optionalViewModifier { content in
            if ipad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
    
}

//MARK: - Phone Territory Cell

struct PhoneTerritoryCellView: View {
    var territory: PhoneTerritory
    var numbers: Int
    var width: Double = 0.95
    
    var mainWindowSize: CGSize
    
    @State private var cellHeight: CGFloat = 0
    
    var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad && mainWindowSize.width > 400
    }
    
    //MARK: - Body
    
    var body: some View {
        HStack(spacing: 10) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .teal]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ).opacity(0.6)
                        )
                    
                    VStack {
                        Text("\(territory.number)")
                            .font(.system(size:  25, weight: .heavy))
                            .foregroundColor(.white)
                        
                    }
                    .frame(minWidth: mainWindowSize.width * 0.20)
                }
                .hSpacing(.leading)
                .frame(width: mainWindowSize.width * 0.20, height: cellHeight, alignment: .center)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(territory.description )
                    .font(.headline)
                    .lineLimit(5)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                Text("Phone Numbers: \(numbers)")
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.secondaryLabel)
                    .fontWeight(.bold)
            }.padding(10)
                .frame(maxWidth: mainWindowSize.width * 0.8, alignment: .leading)
            //Image("testTerritoryImage")
                .vSpacing(.top)
            
        }
        //.id(territory.id)
        //.padding(5)
        .frame(minWidth: mainWindowSize.width * width)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    self.cellHeight = geometry.size.height
                    print("Cell height: \(self.cellHeight)")
                }
        })
        .optionalViewModifier { content in
            if isIpad {
                content
                    .frame(maxHeight: .infinity)
            } else {
                content
            }
        }
    }
    
}

//MARK: - Territory Recent Cell

struct recentCell: View {
    var territoryData: RecentTerritoryData
    
    var mainWindowSize: CGSize
    
    //MARK: - Body
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.6)
                    )
                VStack {
                    Text("\(territoryData.territory.number)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: mainWindowSize.width * 0.20)
                
                
            }
            .hSpacing(.leading)
            .frame(width: mainWindowSize.width * 0.20, height: 50, alignment: .center)
            
            Text("\(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(territoryData.lastVisit.date) / 1000), withTime: false))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondaryLabel)
                .frame(width: mainWindowSize.width * 0.20, alignment: .center)
                .lineLimit(2)
        }
    }
}

struct RecentTerritoryCellView: View {
    let territoryData: RecentTerritoryData
    let mainWindowSize: CGSize
    let index: Int
    let viewModel: TerritoryViewModel
    var dominoStartDelay: Double? = nil // 👈 NEW

    @State private var navigate = false
    @State private var appeared = false
    @State private var scale: CGFloat = 1.15
    @State private var shrinkTimer: Timer? = nil

    var body: some View {
        ZStack {
            NavigationLink(
                destination: NavigationLazyView(TerritoryAddressView(territory: territoryData.territory)),
                isActive: $navigate,
                label: { EmptyView() }
            ).hidden()

            recentCell(territoryData: territoryData, mainWindowSize: mainWindowSize)
                .scaleEffect(scale)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .shadow(color: appeared ? .clear : Color.blue.opacity(0.2), radius: 10, y: 10)
                .contentShape(Rectangle()) // Make entire area tappable
                .gesture(
                    ExclusiveGesture(
                        // Tap Gesture
                        TapGesture()
                            .onEnded {
                                HapticManager.shared.trigger(.impact)
                                animateScale(to: 0.95)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    animateScale(to: 1.0)
                                    navigate = true
                                }
                            },
                        // Long Press Gesture
                        LongPressGesture(minimumDuration: 0.5)
                            .onChanged { _ in
                                startShrinking()
                            }
                            .onEnded { _ in
                                stopShrinking()
                                HapticManager.shared.trigger(.impact)
                                CentrePopup_RecentFloorsKnocked(
                                    viewModel: FloorsViewModel(territory: territoryData.territory)
                                ) {}.present()
                            }
                    )
                )
                .onDisappear {
                    stopShrinking()
                }
                .onAppear {
                    guard !appeared else { return }

                    let baseDelay = dominoStartDelay ?? 0 // if nil, start immediately
                    let totalDelay = baseDelay + Double(index) * 0.08

                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        withAnimation(.interpolatingSpring(stiffness: 200, damping: 18)) {
                            appeared = true
                            scale = 1.0
                        }

                        if index == viewModel.recentTerritoryData!.count - 1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                viewModel.hasAnimatedRecentTerritories = true
                            }
                        }
                    }
                }
        }
    }

    // MARK: - Scale Handling

    func animateScale(to value: CGFloat) {
        withAnimation(.easeInOut(duration: 0.15)) {
            scale = value
        }
    }

    func startShrinking() {
        stopShrinking()
        shrinkTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                if scale > 0.88 {
                    scale -= 0.01
                }
            }
        }
    }

    func stopShrinking() {
        shrinkTimer?.invalidate()
        shrinkTimer = nil
        animateScale(to: 1.0)
    }
}
//MARK: - Phone Territory Recent Cell

struct recentPhoneCell: View {
    var territoryData: RecentPhoneData
    
    var mainWindowSize: CGSize
    
    //MARK: - Body
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .teal]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.6)
                    )
                VStack {
                    Text("\(territoryData.territory.number)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(minWidth: mainWindowSize.width * 0.20)
                
                
            }
            .hSpacing(.leading)
            .frame(width: mainWindowSize.width * 0.20, height: 50, alignment: .center)
            
            Text("\(formattedDate(date: Date(timeIntervalSince1970: TimeInterval(territoryData.lastCall.date) / 1000), withTime: false))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondaryLabel)
                .frame(width: mainWindowSize.width * 0.20, alignment: .center)
                .lineLimit(2)
        }
    }
}


struct CentrePopup_RecentFloorsKnocked: CentrePopup {
    @ObservedObject var viewModel: FloorsViewModel
    var onDone: () -> Void
    
    init(viewModel: FloorsViewModel, onDone: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDone = onDone
    }
    
    var body: some View {
        createContent()
    }
    
    func createContent() -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 15) {
                
                // Title
                Text("Knocking Info")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                    .padding(.leading, 20)  // small left padding for styling
                Text("Territory \(viewModel.territory.number)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .fontWeight(.bold)
                    .padding(.leading, 20)  // small left padding for styling
                    .padding(.top, -8)
                
                // Floors
                if viewModel.floorDetails.isEmpty {
                    Text("No recent floors knocked.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.floorDetails, id: \.address.id) { detail in
                                FloorCellView(detail: detail)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Done Button
                HStack {
                    Spacer()
                    CustomButton(loading: false, title: "Done") {
                        HapticManager.shared.trigger(.lightImpact)
                        withAnimation {
                            dismissLastPopup()
                            onDone()
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .background(Material.thin)
            .cornerRadius(16)
            .ignoresSafeArea(.keyboard)
        }
        // Note: NO .padding(.horizontal, ...) here
        .ignoresSafeArea(.keyboard)
    }
    
    /// Here we place the horizontal padding of the entire popup
    /// so that the content is inset from the screen edges by 24 points on each side.
    func configurePopup(config: CentrePopupConfig) -> CentrePopupConfig {
        config.popupHorizontalPadding(40)
    }
}



@MainActor
class FloorsViewModel: ObservableObject {
    @Published var territory: Territory
    @Published var floorData: FloorData?
    
    init(territory: Territory) {
        self.territory = territory
        Task { [weak self] in
            await self?.loadFloorData()
        }
    }
    
    func loadFloorData() async {
        floorData = await GRDBManager.shared.getFloorData(for: territory.id)
    }
    
    /// Convenience computed property returning the floor details (addresses) for the territory.
    var floorDetails: [FloorDetail] {
        floorData?.floors ?? []
    }
}


struct FloorCellView: View {
    let detail: FloorDetail
    
    var body: some View {
        HStack(spacing: 12) {
            // Text information
            VStack(alignment: .leading, spacing: 4) {
                Text(detail.address.address)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let knockedDate = detail.knockedDate {
                    Text("Knocked: \(formattedDate(knockedDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not Knocked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status icon
            let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
            let isKnockedRecently = detail.knockedDate.map { $0 >= twoWeeksAgo } ?? false
            
            Image(systemName: isKnockedRecently ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isKnockedRecently ? Color.green : Color.red)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
    }
    
    /// Formats the date to a medium style string.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Returns a gradient based on whether the floor was knocked recently.
    private var gradientColors: [Color] {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        guard let knockedDate = detail.knockedDate, knockedDate >= twoWeeksAgo else {
            // Red gradient for old or missing knock date
            return [Color.red.opacity(0.35), Color.red.opacity(0.20)]
        }
        // Green gradient for recent knock date
        return [Color.green.opacity(0.35), Color.green.opacity(0.20)]
    }
}
