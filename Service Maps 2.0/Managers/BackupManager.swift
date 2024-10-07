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
    @ObservedObject var realmManager = RealmManager.shared
    static var shared = BackupManager()
    var backupTask: Task<Void, Never>?  // Track the backup task
    @Published var progress: Double = 0.0 {
        didSet {
            print("Progress: \(progress)")
        }
    }
    
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
                case .success(let url):
                    self.isBackingUp = false
                    print("Backup completed successfully.")
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
        if await isBackingUp == true {
            print("Backup in progress canceled. Please try again.")
            return Result.failure(NSError(domain: "Backup in Progress", code: 100, userInfo: nil))
        }
        
        DispatchQueue.main.async {
            self.progress = 0.0  // Initialize progress
            self.isBackingUp = true
        }
        
        // Create a serial queue for safely updating progress
        let progressTracker = ProgressTracker()  // Actor for thread-safe progress track
        
        // Check for task cancellation early
        if Task.isCancelled {
            print("Task was canceled before starting.")
            return .failure(NSError(domain: "Backup Canceled", code: 1, userInfo: nil))
        }
        
        // Begin the backup process
        let territories = await realmManager.getAllTerritoriesDirectAsync()
        let addresses = await realmManager.getAllAddressesDirectAsync()
        let houses = await realmManager.getAllHousesDirectAsync()
        let visits = await realmManager.getAllVisitsDirectAsync()
        
        let totalItems: Double = Double(territories.count) + Double(addresses.count)
        
        // Convert fetched data
        let territoryModels = territories.toTerritoryModels()
        let addressModels = addresses.toTerritoryAddressModels()
        let houseModels = houses.toHouseModels()
        let visitModels = visits.toVisitModels()
        
        guard let pdfURL = Bundle.main.url(forResource: "s8NEW", withExtension: "pdf"),
              let pdfDocument = PDFDocument(url: pdfURL) else {
            return Result.failure(CustomErrors.GenericError)
        }
        
        let date = await getCurrentDate()
        guard let backupFolder = await createBackupFolder(date: date) else {
            return Result.failure(CustomErrors.GenericError)
        }
        
        let data = await orderAllData(territories: territoryModels, addressesList: addressModels, houseList: houseModels, visits: visitModels)
        
        // Track concurrent tasks
        var writeTasks = [Task<Void, Never>]()
        
        for territory in data {
            if Task.isCancelled { // Check for cancellation before starting each territory
                print("Backup was canceled during territory processing.")
                return .failure(NSError(domain: "Backup Canceled", code: 1, userInfo: nil))
            }
            
            let territoryFolderURL = await createTerritoryFolder(backupFolder: backupFolder, territory: territory.territory)
            
            var doors = 0
            for address in territory.addresses {
                doors += address.houses.count
            }
            await saveTerritoryTextFile(territory: territory.territory, territoryFolder: territoryFolderURL, doors: doors)
            
            for address in territory.addresses {
                if Task.isCancelled { // Check for cancellation before processing each address
                    print("Backup was canceled during address processing.")
                    return .failure(NSError(domain: "Backup Canceled", code: 1, userInfo: nil))
                }
                
                await progressTracker.incrementProcessedItems()
                    let progress = await progressTracker.getProgress(totalItems: totalItems)
                    DispatchQueue.main.async {
                        self.progress = progress
                    }
                
                if address.houses.count > 96 {
                    var split = [AddressWithHouses]()
                    for houses in address.houses.divideIn(96) {
                        split.append(AddressWithHouses(address: address.address, houses: houses))
                    }
                    for (index, addressWithHouses) in split.enumerated() {
                        let writeTask = Task {
                            await self.writeS8(parentFolder: territoryFolderURL, territoryNumber: String(territory.territory.number), address: addressWithHouses, version: index + 1)
                        }
                        writeTasks.append(writeTask)
                    }
                } else {
                    let writeTask = Task {
                        await self.writeS8(parentFolder: territoryFolderURL, territoryNumber: String(territory.territory.number), address: address)
                    }
                    writeTasks.append(writeTask)
                }
            }
            
            // Increment processed items using the actor and update progress on the main thread
            await progressTracker.incrementProcessedItems()
            let progress = await progressTracker.getProgress(totalItems: totalItems)
            DispatchQueue.main.async {
                self.progress = progress
            }
        }
        
        // Await all tasks to finish
        for task in writeTasks {
            if Task.isCancelled { // Check for cancellation before awaiting each task
                print("Backup was canceled during file writing.")
                return .failure(NSError(domain: "Backup Canceled", code: 1, userInfo: nil))
            }
            await task.value
        }
        
        // Zip the backup folder
        let zipFileName = "Backup-\(date).zip"
        let zipFileURL = backupFolder.deletingLastPathComponent().appendingPathComponent(zipFileName)
        
        do {
            try await zipBackupFolder(sourceURL: backupFolder, destinationURL: zipFileURL)
            try FileManager.default.removeItem(at: backupFolder)
        } catch {
            return .failure(error)
        }
        
        DispatchQueue.main.async {
            self.isBackingUp = false
        }
        return .success(zipFileURL)
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
        
        print("Starting PDF creation for: \(fileName)")
        print("Output path: \(outputFileURL.path)")
        
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
        
        // Assign the STREET and Terr No fields for Form 3
        if let streetAnnotation3 = page.annotations.first(where: { $0.fieldName == "STREET3_1" }) {
            streetAnnotation3.widgetStringValue = address.address.address
        }
        
        if let terrNoAnnotation3 = page.annotations.first(where: { $0.fieldName == "Terr No3_1" }) {
            terrNoAnnotation3.widgetStringValue = territoryNumber
        }
        
        // Assign the STREET and Terr No fields for Form 4
        if let streetAnnotation4 = page.annotations.first(where: { $0.fieldName == "STREET4_1" }) {
            streetAnnotation4.widgetStringValue = address.address.address
        }
        
        if let terrNoAnnotation4 = page.annotations.first(where: { $0.fieldName == "Terr No4_1" }) {
            terrNoAnnotation4.widgetStringValue = territoryNumber
        }
        // Divide the houses into chunks of 24, one for each form
        let houseDataChunks = address.houses.divideIn(24)
        
        if Task.isCancelled { // Check for cancellation before starting
            return
        }
        // Write data to each form using hardcoded field names
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
        
        if Task.isCancelled { // Check for cancellation before starting
            return
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
    private func createTerritoryFolder(backupFolder: URL, territory: TerritoryModel) async -> URL {
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
    private func saveTerritoryTextFile(territory: TerritoryModel, territoryFolder: URL, doors: Int) async {
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
                print("Created destination folder at: \(destinationFolder.path)")
            } catch {
                print("Failed to create destination folder: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Ensure no existing zip file blocks the creation
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
                print("Removed existing zip file at: \(destinationURL.path)")
            } catch {
                print("Failed to remove existing zip file: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Log paths for debugging
        print("Zipping from: \(sourceURL.path) to: \(destinationURL.path)")
        
        // Use the new zip method provided in your URL extension
        do {
            let zipURL = try await sourceURL.zip(toFileAt: destinationURL)
            print("Successfully zipped the folder to: \(zipURL.path)")
        } catch {
            print("Failed to zip the folder: \(error.localizedDescription)")
            throw error
        }
        
        print("Zip archive successfully created at: \(destinationURL.path)")
    }
    @BackgroundActor
    private func orderAllData(
        territories: [TerritoryModel],
        addressesList: [TerritoryAddressModel],
        houseList: [HouseModel],
        visits: [VisitModel]
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
    let house: HouseModel
    let visit: VisitModel?
}

struct AddressWithHouses {
    let address: TerritoryAddressModel
    let houses: [HouseWithVisit]
}

struct TerritoryWithAddresses {
    let territory: TerritoryModel
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

@BackgroundActor
extension Array where Element == VisitObject {
    func toVisitModels() -> [VisitModel] {
        return self.map { entity in
            VisitModel(id: entity.id,
                       house: entity.house,
                       date: Int64(entity.date),
                       symbol: entity.symbol == "uk" ? "-" : entity.symbol.uppercased(),
                       notes: entity.notes,
                       user: entity.user,
                       created_at: "", updated_at: "")
        }
    }
}
@BackgroundActor
extension Array where Element == TerritoryAddressObject {
    func toTerritoryAddressModels() -> [TerritoryAddressModel] {
        return self.map { entity in
            TerritoryAddressModel(id: entity.id,
                                  territory: entity.territory,
                                  address: entity.address,
                                  floors: entity.floors,
                                  created_at: "", updated_at: "")
        }
    }
}
@BackgroundActor
extension Array where Element == TerritoryObject {
    func toTerritoryModels() -> [TerritoryModel] {
        return self.map { entity in
            TerritoryModel(id: entity.id,
                           congregation: entity.congregation,
                           number: entity.number,
                           description: entity.territoryDescription,
                           image: entity.image,
                           created_at: "", updated_at: "")
        }
    }
}
@BackgroundActor
extension Array where Element == HouseObject {
    func toHouseModels() -> [HouseModel] {
        return self.map { entity in
            HouseModel(id: entity.id,
                       territory_address: entity.territory_address,
                       number: entity.number,
                       floor: entity.floor,
                       created_at: "", updated_at: "")
        }
    }
}
