import Foundation
import PDFKit
import SwiftUI
import ZIPFoundation
import Nuke

actor ProgressTracker {
    private(set) var processedItems: Double = 0.0
    
    func incrementProcessedItems() {
        processedItems += 1
    }
    
    func getProgress(totalItems: Double) -> Double {
        return processedItems / totalItems
    }
}

class BackupManager: ObservableObject {
    @Published var isBackingUp: Bool = false
    @Published var backup = false
    @ObservedObject var grdbManager = GRDBManager.shared
    static var shared = BackupManager()
    var backupTask: Task<Void, Never>?  // Track the backup task
    @Published var progress: Double = 0.0
    
    let fileManager = FileManager.default
    
    // Hardcoded field names for 4 forms (each form contains up to 24 entries)
    private let form1Fields = (1...24).map { "HOUSE1_\($0)" }
    private let form2Fields = (1...24).map { "HOUSE2_\($0)" }
    private let form3Fields = (1...24).map { "HOUSE3_\($0)" }
    private let form4Fields = (1...24).map { "HOUSE4_\($0)" }
    
    private let dateFields1 = (1...24).map { "FechaRow1_\($0)" }
    private let dateFields2 = (1...24).map { "FechaRow2_\($0)" }
    private let dateFields3 = (1...24).map { "FechaRow3_\($0)" }
    private let dateFields4 = (1...24).map { "FechaRow4_\($0)" }
    
    private let symbolFields1 = (1...24).map { "S1_\($0)" }
    private let symbolFields2 = (1...24).map { "S2_\($0)" }
    private let symbolFields3 = (1...24).map { "S3_\($0)" }
    private let symbolFields4 = (1...24).map { "S4_\($0)" }
    
    private let noteFields1 = (1...24).map { "Nombre colocaciones y observacionesRow1_\($0)" }
    private let noteFields2 = (1...24).map { "Nombre colocaciones y observacionesRow2_\($0)" }
    private let noteFields3 = (1...24).map { "Nombre colocaciones y observacionesRow3_\($0)" }
    private let noteFields4 = (1...24).map { "Nombre colocaciones y observacionesRow4_\($0)" }
    
    func cancelBackup() {
        backupTask?.cancel()
        isBackingUp = false
        backupTask = nil
        progress = 0.0
        print("Backup cancelled.")
    }
    
    // Main backup function
    func startBackup() {
        backupTask = Task { [weak self] in
            guard let self = self else { return }
            let result = await self.backupFiles()
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.isBackingUp = false
                    // Handle success, present the activity view controller, etc.
                case .failure(let error):
                    self.isBackingUp = false
                    print("Backup failed with error: \(error.localizedDescription)")
                    // Handle failure, show error message, etc.
                }
            }
        }
    }
    
    // Main backup function
    // Main backup function with cancellation check
    @BackgroundActor
    func backupFiles() async -> Result<URL, Error> {
        // Check if backup is already in progress
        if await isBackingUp == true {
            return Result.failure(NSError(domain: "Backup in Progress", code: 100, userInfo: nil))
        }
        
        // Reset progress and mark as backing up
        DispatchQueue.main.async {
            self.progress = 0.0  // Reset progress
            self.isBackingUp = true
        }
        
        // Start fetching data directly from GRDB
        var territories = [Territory]()
        var addresses = [TerritoryAddress]()
        var houses = [House]()
        var visits = [Visit]()
        
        do {
            // Fetch data from database
            let territoriesResult = await grdbManager.fetchAllAsync(Territory.self)
            let addressesResult = await grdbManager.fetchAllAsync(TerritoryAddress.self)
            let housesResult = await grdbManager.fetchAllAsync(House.self)
            let visitsResult = await grdbManager.fetchAllAsync(Visit.self)
            
            switch (territoriesResult, addressesResult, housesResult, visitsResult) {
            case (.success(let allTerritories), .success(let allAddresses), .success(let allHouses), .success(let allVisits)):
                territories = allTerritories
                houses = allHouses
                addresses = allAddresses
                visits = allVisits
                
            case (.failure(let error), _, _, _), (_, .failure(let error), _, _), (_, _, .failure(let error), _), (_, _, _, .failure(let error)):
                // Handle errors
                return Result.failure(error)
            }
            
        } catch {
            // Handle fetch error
            return Result.failure(error)
        }
        
        // Calculate total items for progress tracking
        let totalItems = Double(territories.count + addresses.count)

        guard let pdfURL = Bundle.main.url(forResource: "s8NEW", withExtension: "pdf"),
              let pdfDoc = PDFDocument(url: pdfURL) else {
            return Result.failure(CustomErrors.GenericError)
        }
        
        let date = await getCurrentDate()
        guard let backupFolder = await createBackupFolder(date: date) else {
            return Result.failure(CustomErrors.GenericError)
        }
        
        let data = await orderAllData(territories: territories, addressesList: addresses, houseList: houses, visits: visits)
        
        // Tasks to handle PDF writing
        var writeTasks = [Task<Void, Never>]()
        
        // Create a progress tracker
        let progressTracker = ProgressTracker()
        
        // Process data and write to files
        for territory in data {
            if Task.isCancelled {
                return .failure(NSError(domain: "Backup Canceled", code: 1, userInfo: nil))
            }
            
            let territoryFolderURL = await createTerritoryFolder(backupFolder: backupFolder, territory: territory.territory)
            
            var doors = 0
            for address in territory.addresses {
                doors += address.houses.count
            }
            
            // Save text file for territory
            await saveTerritoryTextFile(territory: territory.territory, territoryFolder: territoryFolderURL, doors: doors)

            // Process each address for backup
            for address in territory.addresses {
                if Task.isCancelled {
                    return .failure(NSError(domain: "Backup Canceled", code: 1, userInfo: nil))
                }
                
                // Increment progress as an address is processed
                await progressTracker.incrementProcessedItems()
                let progress = await progressTracker.getProgress(totalItems: totalItems)
                DispatchQueue.main.async {
                    withAnimation {
                        self.progress = progress
                    }
                }
                
                // Process address backup
                await processAddressBackup(address, territoryFolderURL: territoryFolderURL, territoryNumber: String(territory.territory.number), writeTasks: &writeTasks)
            }
        }
        
        // Await all tasks to finish
        for task in writeTasks {
            if Task.isCancelled {
                return .failure(NSError(domain: "Backup Canceled", code: 1, userInfo: nil))
            }
            await task.value
            
            // Increment progress as each task finishes
            await progressTracker.incrementProcessedItems()
            let progress = await progressTracker.getProgress(totalItems: totalItems)
            DispatchQueue.main.async {
                withAnimation {
                    self.progress = progress
                }
            }
        }

        // Zip the backup folder
        let zipFileName = "Backup-\(date).zip"
        let zipFileURL = backupFolder.deletingLastPathComponent().appendingPathComponent(zipFileName)
        
        let result = await performFileOperations(sourceURL: backupFolder, backupFolder: backupFolder, zipFileURL: zipFileURL)
        if case .failure(let error) = result {
            return .failure(error)
        }

        // Mark backup as complete
        DispatchQueue.main.async {
            self.isBackingUp = false
        }

        return .success(zipFileURL)
    }
    
    @MainActor // Marking this function to run on the main actor since `FileManager` isn't sendable
    func performFileOperations(sourceURL: URL, backupFolder: URL, zipFileURL: URL) async -> Result<URL, Error> {
        do {
            // Zip the backup folder asynchronously
            try await zipBackupFolder(sourceURL: backupFolder, destinationURL: zipFileURL)
            
            // Perform file removal on the main thread (because FileManager is not sendable)
            try fileManager.removeItem(at: backupFolder)
            
            return .success(zipFileURL)
        } catch {
            return .failure(error)
        }
    }
    
    @BackgroundActor
    private func processAddressBackup(_ address: AddressWithHouses, territoryFolderURL: URL, territoryNumber: String, writeTasks: inout [Task<Void, Never>]) async {
        if address.houses.count > 96 {
            let split = address.houses.divideIn(96)
            for (index, housesChunk) in split.enumerated() {
                // Create a new AddressWithHouses for each chunk
                let splitAddressWithHouses = AddressWithHouses(address: address.address, houses: housesChunk)
                
                let writeTask = Task {
                    await self.writeS8(parentFolder: territoryFolderURL, territoryNumber: territoryNumber, address: splitAddressWithHouses, version: index + 1)
                }
                writeTasks.append(writeTask)
            }
        } else {
            let writeTask = Task {
                await self.writeS8(parentFolder: territoryFolderURL, territoryNumber: territoryNumber, address: address)
            }
            writeTasks.append(writeTask)
        }
    }
    
    @BackgroundActor
    func writeS8(
        parentFolder: URL,
        territoryNumber: String,
        address: AddressWithHouses,
        version: Int? = nil
    ) async {
        if Task.isCancelled { // Check for cancellation before starting
            return
        }
        
        let safeAddress = address.address.address.replacingOccurrences(of: " ", with: "_")
        let fileName = version == nil ? "\(safeAddress).pdf" : "\(safeAddress)_(\(version!)).pdf"
        let outputFileURL = parentFolder.appendingPathComponent(fileName)
        
        guard let pdfURL = Bundle.main.url(forResource: "s8NEW", withExtension: "pdf") else {
            print("Failed to find template PDF in bundle")
            return
        }
        
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            print("Failed to create PDF document from template")
            return
        }
        
        guard let page = pdfDocument.page(at: 0) else {
            print("Failed to get first page")
            return
        }
        
        // Assign the STREET and Terr No fields for Form 1
        if let streetAnnotation1 = page.annotations.first(where: { $0.fieldName == "STREET1_1" }) {
            streetAnnotation1.widgetStringValue = address.address.address
        }
        
        if let terrNoAnnotation1 = page.annotations.first(where: { $0.fieldName == "Terr No1_1" }) {
            terrNoAnnotation1.widgetStringValue = territoryNumber
        }
        
        // Assign the STREET and Terr No fields for Form 2
        if let streetAnnotation2 = page.annotations.first(where: { $0.fieldName == "STREET2_1" }) {
            streetAnnotation2.widgetStringValue = address.address.address
        }
        
        if let terrNoAnnotation2 = page.annotations.first(where: { $0.fieldName == "Terr No2_1" }) {
            terrNoAnnotation2.widgetStringValue = territoryNumber
        }
        
        // Continue similar for Form 3 and Form 4 (this pattern is reused)
        if Task.isCancelled { return }

        // Divide the houses into chunks of 24, one for each form
        let houseDataChunks = address.houses.divideIn(24)
        
        if Task.isCancelled { return }

        // Write data to each form using the field mapping
        for (formIndex, dataChunk) in houseDataChunks.enumerated() {
            let houseFields = await getHouseFields(for: formIndex)
            let dateFields = await getDateFields(for: formIndex)
            let symbolFields = await getSymbolFields(for: formIndex)
            let noteFields = await getNoteFields(for: formIndex)
            
            for (index, houseData) in dataChunk.enumerated() {
                if index < houseFields.count {
                    // Assign house number
                    if let houseAnnotation = page.annotations.first(where: { $0.fieldName == houseFields[index] }) {
                        houseAnnotation.widgetStringValue = houseData.house.number
                    }
                    
                    // Assign date, symbol, and notes if there is a visit
                    if let visit = houseData.visit {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        
                        if let dateAnnotation = page.annotations.first(where: { $0.fieldName == dateFields[index] }) {
                            dateAnnotation.widgetStringValue = dateFormatter.string(from: Date(milliseconds: visit.date))
                        }
                        
                        if let symbolAnnotation = page.annotations.first(where: { $0.fieldName == symbolFields[index] }) {
                            symbolAnnotation.widgetStringValue = visit.symbol
                        }
                        
                        if let noteAnnotation = page.annotations.first(where: { $0.fieldName == noteFields[index] }) {
                            noteAnnotation.widgetStringValue = visit.notes
                        }
                    }
                }
            }
        }

        pdfDocument.write(to: outputFileURL)
        DispatchQueue.main.async {
            if !self.fileManager.fileExists(atPath: outputFileURL.path) {
                print("Error: Failed to create PDF at path \(outputFileURL.path)")
            } else {
                print("PDF successfully created at path \(outputFileURL.path)")
            }
        }
    }
    
    @BackgroundActor
    private func getHouseFields(for formIndex: Int) async -> [String] {
        switch formIndex {
        case 0: return form1Fields
        case 1: return form2Fields
        case 2: return form3Fields
        case 3: return form4Fields
        default: return []
        }
    }
    @BackgroundActor
    private func getDateFields(for formIndex: Int) async -> [String] {
        switch formIndex {
        case 0: return dateFields1
        case 1: return dateFields2
        case 2: return dateFields3
        case 3: return dateFields4
        default: return []
        }
    }
    @BackgroundActor
    private func getSymbolFields(for formIndex: Int) async -> [String] {
        switch formIndex {
        case 0: return symbolFields1
        case 1: return symbolFields2
        case 2: return symbolFields3
        case 3: return symbolFields4
        default: return []
        }
    }
    @BackgroundActor
    private func getNoteFields(for formIndex: Int) async -> [String] {
        switch formIndex {
        case 0: return noteFields1
        case 1: return noteFields2
        case 2: return noteFields3
        case 3: return noteFields4
        default: return []
        }
    }
    
    // Helper methods for managing backup folders, territory folders, and zipping files
    @BackgroundActor
    private func getCurrentDate() async -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        return dateFormatter.string(from: Date())
    }
    @BackgroundActor
    private func createBackupFolder(date: String) async -> URL? {
        let fileManager = FileManager.default
        let applicationSupportDirectory = fileManager.urls(for: .documentDirectory, in: .allDomainsMask).first!
        let backupFolder = applicationSupportDirectory.appendingPathComponent("Backup-\(date)")
        
        do {
            try fileManager.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        } catch {
            print("Failed to create backup folder: \(error.localizedDescription)")
            return nil
        }
        
        return backupFolder
    }
    @BackgroundActor
    private func createTerritoryFolder(backupFolder: URL, territory: Territory) async -> URL {
        let territoryFolder = backupFolder.appendingPathComponent("T-\(territory.number)")
        
        // Create the territory folder if it doesn't exist
        DispatchQueue.main.async {
            if !self.fileManager.fileExists(atPath: territoryFolder.path) {
                try? self.fileManager.createDirectory(at: territoryFolder, withIntermediateDirectories: true)
            }
        }
        
        // Check if the territory has an image URL and try to download it using Nuke
        if let imageLink = URL(string: territory.getImageURL()) {
            do {
                // Download the image asynchronously using Nuke
                let imageResponse = try await ImagePipeline.shared.image(for: imageLink)
                
                // Save the downloaded image to the territory folder
                let imageFileURL = territoryFolder.appendingPathComponent("TerritoryImage-\(territory.number).jpg")
                
                // Convert the image to JPEG data
                if let jpegData = imageResponse.jpegData(compressionQuality: 1.0) {
                    try jpegData.write(to: imageFileURL)
                    print("Territory image saved at path: \(imageFileURL.path)")
                } else {
                    print("Failed to convert image to JPEG data")
                }
                
            } catch {
                print("Failed to download image: \(error.localizedDescription)")
            }
        } else {
            print("Territory does not have a valid image URL")
        }
        
        return territoryFolder
    }
    @BackgroundActor
    private func saveTerritoryTextFile(territory: Territory, territoryFolder: URL, doors: Int) async {
        let text = "\(territory.description)\nDoors: \(doors)"
        let textFileURL = territoryFolder.appendingPathComponent("\(territory.number).txt")
        try? text.write(to: textFileURL, atomically: true, encoding: .utf8)
    }
    
    @BackgroundActor
    func zipBackupFolder(sourceURL: URL, destinationURL: URL) async throws {
        let fileManager = FileManager.default
        
        // Ensure the destination folder exists
        let destinationFolder = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationFolder.path) {
            do {
                try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            } catch {
                print("Failed to create destination folder: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Ensure no existing zip file blocks the creation
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch {
                print("Failed to remove existing zip file: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Use the new zip method provided in your URL extension
        do {
            let zipURL = try await sourceURL.zip(toFileAt: destinationURL)
        } catch {
            print("Failed to zip the folder: \(error.localizedDescription)")
            throw error
        }
    }
    @BackgroundActor
    private func orderAllData(
        territories: [Territory],
        addressesList: [TerritoryAddress],
        houseList: [House],
        visits: [Visit]
    ) async -> [TerritoryWithAddresses] {
        var list = [TerritoryWithAddresses]()
        for territory in territories {
            var addresses = [AddressWithHouses]()
            let filteredAddresses = addressesList.filter { $0.territory == territory.id }
            for address in filteredAddresses {
                var houses = [HouseWithVisit]()
                let filteredHouses = houseList.filter { $0.territory_address == address.id }
                for house in filteredHouses {
                    let visit = visits
                        .filter { $0.house == house.id && $0.symbol != "NC" }
                        .max(by: { $0.date < $1.date }) ?? visits
                        .filter { $0.house == house.id }
                        .max(by: { $0.date < $1.date })
                    houses.append(HouseWithVisit(house: house, visit: visit))
                }
                addresses.append(AddressWithHouses(
                    address: address,
                    houses: houses.sorted(by: { $0.house.number < $1.house.number })
                ))
            }
            list.append(TerritoryWithAddresses(
                territory: territory,
                addresses: addresses.sorted(by: { $0.address.address < $1.address.address })
            ))
        }
        return list.sorted(by: { $0.territory.number < $1.territory.number })
    }
    
}

// Structs used in the BackupManager
struct HouseWithVisit {
    let house: House
    let visit: Visit?
}

struct AddressWithHouses {
    let address: TerritoryAddress
    let houses: [HouseWithVisit]
}

struct TerritoryWithAddresses {
    let territory: Territory
    let addresses: [AddressWithHouses]
}

extension URL {
    @BackgroundActor
    func relativePath(from base: URL) async -> String {
        let selfStr = self.standardized.path
        let baseStr = base.standardized.path
        if selfStr.hasPrefix(baseStr) {
            let index = selfStr.index(selfStr.startIndex, offsetBy: baseStr.count)
            return String(selfStr[index...]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return self.lastPathComponent
    }
}


public extension URL {
    
    /// Creates a zip archive of the file or folder represented by this URL and returns a references to the zipped file
    ///
    /// - parameter dest: the destination URL; if nil, the destination will be this URL with ".zip" appended
    @BackgroundActor
    func zip(toFileAt dest: URL? = nil) async throws -> URL
    {
        let destURL = dest ?? self.appendingPathExtension("zip")
        
        let fm = FileManager.default
        var isDir: ObjCBool = false
        
        let srcDir: URL
        let srcDirIsTemporary: Bool
        if self.isFileURL && fm.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue == true {
            // this URL is a directory: just zip it in-place
            srcDir = self
            srcDirIsTemporary = false
        }
        else {
            // otherwise we need to copy the simple file to a temporary directory in order for
            // NSFileCoordinatorReadingOptions.ForUploading to actually zip it up
            srcDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try fm.createDirectory(at: srcDir, withIntermediateDirectories: true, attributes: nil)
            let tmpURL = srcDir.appendingPathComponent(self.lastPathComponent)
            try fm.copyItem(at: self, to: tmpURL)
            srcDirIsTemporary = true
        }
        
        let coord = NSFileCoordinator()
        var readError: NSError?
        var copyError: NSError?
        var errorToThrow: NSError?
        
        var readSucceeded:Bool = false
        // coordinateReadingItemAtURL is invoked synchronously, but the passed in zippedURL is only valid
        // for the duration of the block, so it needs to be copied out
        coord.coordinate(readingItemAt: srcDir,
                         options: NSFileCoordinator.ReadingOptions.forUploading,
                         error: &readError)
        {
            (zippedURL: URL) -> Void in
            readSucceeded = true
            // assert: read succeeded
            do {
                try fm.copyItem(at: zippedURL, to: destURL)
            } catch let caughtCopyError {
                copyError = caughtCopyError as NSError
            }
        }
        
        if let theReadError = readError, !readSucceeded {
            // assert: read failed, readError describes our reading error
            NSLog("%@","zipping failed")
            errorToThrow =  theReadError
        }
        else if readError == nil && !readSucceeded  {
            NSLog("%@","NSFileCoordinator has violated its API contract. It has errored without throwing an error object")
            errorToThrow = NSError.init(domain: Bundle.main.bundleIdentifier!, code: 0, userInfo: nil)
        }
        else if let theCopyError = copyError {
            // assert: read succeeded, copy failed
            NSLog("%@","zipping succeeded but copying the zip file failed")
            errorToThrow = theCopyError
        }
        
        if srcDirIsTemporary {
            do {
                try fm.removeItem(at: srcDir)
            }
            catch {
                // Not going to throw, because we do have a valid output to return. We're going to rely on
                // the operating system to eventually cleanup the temporary directory.
                NSLog("%@","Warning. Zipping succeeded but could not remove temporary directory afterwards")
            }
        }
        if let error = errorToThrow { throw error }
        return destURL
    }
}

public extension NSData {
    /// Creates a zip archive of this data via a temporary file and returns the zipped contents
    @BackgroundActor
    func zip() async throws -> NSData {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try self.write(to: tmpURL, options: NSData.WritingOptions.atomic)
        let zipURL = try await tmpURL.zip()
        let fm = FileManager.default
        let zippedData = try NSData(contentsOf: zipURL, options: NSData.ReadingOptions())
        try fm.removeItem(at: tmpURL) // clean up
        try fm.removeItem(at: zipURL)
        return zippedData
    }
}
