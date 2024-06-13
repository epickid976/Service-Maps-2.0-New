import Foundation
import SwiftUI
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var dataStore = StorageManager.shared
    @Published var realmManager = RealmManager.shared
    @Published var searchResults: [MySearchResult] = []
    @Published var searchQuery: String = ""
    @Published var searchState: SearchState = .Idle {
        didSet {
            print("Search state changed to: \(searchState)")
        }
    }
    @Published var searchMode: SearchMode = .Territories
    
    private var cancellables = Set<AnyCancellable>()
    
    init(mode: SearchMode = .Territories) {
        self.searchMode = mode
        setupSearchQueryObserver()
    }
    
    private func setupSearchQueryObserver() {
        $searchQuery
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main) // Increase debounce duration for better effect
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.getSearchResults()
                } else {
                    self?.searchState = .Idle
                }
            }
            .store(in: &cancellables)
    }
    
    func isLoaded() -> Bool {
        return !searchResults.isEmpty
    }
}

struct MySearchResult: Hashable, Identifiable {
    var id = UUID()
    var type: SearchResultType
    var territory: TerritoryModel? = nil
    var address: TerritoryAddressModel? = nil
    var house: HouseModel? = nil
    var visit: VisitModel? = nil
    var phoneTerritory: PhoneTerritoryModel? = nil
    var number: PhoneNumberModel? = nil
    var call: PhoneCallModel? = nil
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(territory)
        hasher.combine(address)
        hasher.combine(house)
        hasher.combine(visit)
        hasher.combine(phoneTerritory)
        hasher.combine(number)
        hasher.combine(call)
    }
    
    static func ==(lhs: MySearchResult, rhs: MySearchResult) -> Bool {
        return lhs.type == rhs.type &&
        lhs.territory == rhs.territory &&
        lhs.address == rhs.address &&
        lhs.house == rhs.house &&
        lhs.visit == rhs.visit &&
        lhs.phoneTerritory == rhs.phoneTerritory &&
        lhs.number == rhs.number &&
        lhs.call == rhs.call
    }
}

enum SearchResultType: String, CaseIterable, Identifiable {
    var id: String { return self.rawValue }
    case Territory, Address, House, Visit, PhoneTerritory, Number, Call
}

enum SearchMode {
    case Territories, PhoneTerritories
}

enum SearchState {
    case Searching, Done, Idle
}

@MainActor
extension SearchViewModel {
    @MainActor
    func getSearchResults() {
        self.searchState = .Searching
        RealmManager.shared.searchEverywhere(query: self.searchQuery, searchMode: searchMode)
            .receive(on: DispatchQueue.main) // Update on main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle errors here
                    print("Error retrieving territory data: \(error)")
                    self.searchState = .Idle
                }
            }, receiveValue: { searchResults in
                self.searchResults = searchResults
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if self.searchQuery.isEmpty {
                        self.searchState = .Idle
                    } else {
                        self.searchState = .Done
                    }
                }
            })
            .store(in: &cancellables)
    }
}
