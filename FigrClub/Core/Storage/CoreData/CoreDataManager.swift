//
//  CoreDataManager.swift
//  FigrClub
//
//  Created by Emerson Balahan Varona on 27/6/25.
//

import Foundation
import CoreData
import Combine

// MARK: - Core Data Manager
final class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    
    private static let modelName = "FigrClub"
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Self.modelName)
        
        // Configure store description
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                Logger.shared.fatal("Core Data failed to load", category: "coredata")
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            } else {
                Logger.shared.info("Core Data loaded successfully", category: "coredata")
            }
            
            DispatchQueue.main.async {
                self?.isLoading = false
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - Contexts
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Initialization
    private init() {
        isLoading = true
        setupNotifications()
    }
    
    // MARK: - Save Operations
    func save(context: NSManagedObjectContext? = nil) {
        let contextToSave = context ?? viewContext
        
        guard contextToSave.hasChanges else {
            Logger.shared.info("No changes to save in Core Data context", category: "coredata")
            return
        }
        
        do {
            try contextToSave.save()
            Logger.shared.info("Core Data context saved successfully", category: "coredata")
        } catch {
            Logger.shared.error("Failed to save Core Data context", error: error, category: "coredata")
            CrashReporter.shared.recordError(error, userInfo: ["context": "coredata_save"])
        }
    }
    
    func saveViewContext() {
        save(context: viewContext)
    }
    
    func saveInBackground(_ operation: @escaping (NSManagedObjectContext) -> Void) {
        let context = backgroundContext
        context.perform { [weak self] in
            operation(context)
            self?.save(context: context)
        }
    }
    
    // MARK: - Batch Operations
    func performBatchDelete<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil
    ) throws {
        let request = NSBatchDeleteRequest(fetchRequest: T.fetchRequest())
        request.resultType = .resultTypeObjectIDs
        
        if let predicate = predicate {
            request.fetchRequest.predicate = predicate
        }
        
        let result = try viewContext.execute(request) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
        
        Logger.shared.info("Batch delete completed for \(T.self)", category: "coredata")
    }
    
    // MARK: - Fetch Operations
    func fetch<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [],
        limit: Int? = nil,
        context: NSManagedObjectContext? = nil
    ) -> [T] {
        let request = T.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        let contextToUse = context ?? viewContext
        
        do {
            let results = try contextToUse.fetch(request) as? [T] ?? []
            Logger.shared.info("Fetched \(results.count) objects of type \(T.self)", category: "coredata")
            return results
        } catch {
            Logger.shared.error("Failed to fetch \(T.self)", error: error, category: "coredata")
            return []
        }
    }
    
    func fetchFirst<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate,
        context: NSManagedObjectContext? = nil
    ) -> T? {
        return fetch(entity: entity, predicate: predicate, limit: 1, context: context).first
    }
    
    func count<T: NSManagedObject>(
        entity: T.Type,
        predicate: NSPredicate? = nil,
        context: NSManagedObjectContext? = nil
    ) -> Int {
        let request = T.fetchRequest()
        request.predicate = predicate
        
        let contextToUse = context ?? viewContext
        
        do {
            return try contextToUse.count(for: request)
        } catch {
            Logger.shared.error("Failed to count \(T.self)", error: error, category: "coredata")
            return 0
        }
    }
    
    // MARK: - Object Management
    func create<T: NSManagedObject>(entity: T.Type, context: NSManagedObjectContext? = nil) -> T {
        let contextToUse = context ?? viewContext
        let entityName = String(describing: entity)
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: contextToUse) else {
            fatalError("Failed to create entity description for \(entityName)")
        }
        
        return T(entity: entityDescription, insertInto: contextToUse)
    }
    
    func delete<T: NSManagedObject>(_ object: T, context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? viewContext
        contextToUse.delete(object)
        Logger.shared.info("Deleted object of type \(T.self)", category: "coredata")
    }
    
    func delete<T: NSManagedObject>(_ objects: [T], context: NSManagedObjectContext? = nil) {
        let contextToUse = context ?? viewContext
        objects.forEach { contextToUse.delete($0) }
        Logger.shared.info("Deleted \(objects.count) objects of type \(T.self)", category: "coredata")
    }
    
    // MARK: - Utility Methods
    func reset() {
        viewContext.rollback()
        Logger.shared.info("Core Data context reset", category: "coredata")
    }
    
    func clearAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            guard let entityName = entity.name else { continue }
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try viewContext.execute(deleteRequest)
                Logger.shared.info("Cleared all data for entity: \(entityName)", category: "coredata")
            } catch {
                Logger.shared.error("Failed to clear data for entity: \(entityName)", error: error, category: "coredata")
            }
        }
        
        save()
    }
    
    // MARK: - Migration Support
    func requiresMigration() -> Bool {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            let model = persistentContainer.managedObjectModel
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            Logger.shared.error("Failed to check migration requirement", error: error, category: "coredata")
            return false
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func contextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
              context !== viewContext else { return }
        
        viewContext.perform {
            self.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Core Data Extensions
extension NSManagedObject {
    static var entityName: String {
        return String(describing: self)
    }
    
    static func fetchRequest<T: NSManagedObject>() -> NSFetchRequest<T> {
        return NSFetchRequest<T>(entityName: entityName)
    }
}

// MARK: - Fetch Request Builder
struct FetchRequestBuilder<T: NSManagedObject> {
    private var fetchRequest: NSFetchRequest<T>
    
    init(entity: T.Type) {
        self.fetchRequest = T.fetchRequest() as! NSFetchRequest<T>
    }
    
    func predicate(_ predicate: NSPredicate) -> Self {
        fetchRequest.predicate = predicate
        return self
    }
    
    func sortBy(_ descriptors: [NSSortDescriptor]) -> Self {
        fetchRequest.sortDescriptors = descriptors
        return self
    }
    
    func limit(_ limit: Int) -> Self {
        fetchRequest.fetchLimit = limit
        return self
    }
    
    func offset(_ offset: Int) -> Self {
        fetchRequest.fetchOffset = offset
        return self
    }
    
    func build() -> NSFetchRequest<T> {
        return fetchRequest
    }
    
    func execute(in context: NSManagedObjectContext = CoreDataManager.shared.viewContext) -> [T] {
        do {
            return try context.fetch(fetchRequest)
        } catch {
            Logger.shared.error("Failed to execute fetch request", error: error, category: "coredata")
            return []
        }
    }
}
