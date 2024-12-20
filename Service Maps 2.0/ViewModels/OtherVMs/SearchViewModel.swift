import Foundation
import SwiftUI
import Combine

// MARK: - SearchViewModel

@MainActor
class SearchViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    @Published var dataStore = StorageManager.shared
    @Published var grdbManager = GRDBManager.shared
    
    // MARK: - Properties
    
    @Published var searchResults: [MySearchResult] = []
    @Published var searchQuery: String = "" {
        didSet {
            searchQuery == "" ? searchState = .Idle : ()
            searchQuery == "" ? scrollViewID = UUID() : ()
            searchQuery == "" ? (searchResults = []) : ()
            
        }
    }
    @Published var searchState: SearchState = .Idle
    @Published var searchMode: SearchMode = .Territories
    @Published var scrollViewID = UUID()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    init(mode: SearchMode = .Territories) {
        self.searchMode = mode
        setupSearchQueryObserver()
    }
    
    // MARK: - Search Observer
    
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
    
    // MARK: - Methods
    
    func isLoaded() -> Bool {
        return !searchResults.isEmpty
    }
}

// MARK: - Search Result Struct

struct MySearchResult: Hashable, Identifiable {
    var id = UUID()
    var type: SearchResultType
    var territory: Territory? = nil
    var address: TerritoryAddress? = nil
    var house: House? = nil
    var visit: Visit? = nil
    var phoneTerritory: PhoneTerritory? = nil
    var number: PhoneNumber? = nil
    var call: PhoneCall? = nil
    
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

// MARK: - Enums

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

// MARK: -  Extension + Publisher
@MainActor
extension SearchViewModel {
    
    // MARK: - Get Search Result
    @MainActor
    func getSearchResults() {
        self.searchState = .Searching
        GRDBManager.shared.searchEverywhere(query: self.searchQuery, searchMode: searchMode)
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
