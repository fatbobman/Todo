//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/26.
//

import Core
import CoreData
import Foundation
import OSLog

public final class CoreDataStack {
    lazy var container: NSPersistentContainer = {
        guard let modelURL = Bundle.module.url(forResource: modelName, withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Can't load \(modelName).momd in Bundle")
        }

        let container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Load Description error:\(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    let modelName: String
    let inMemory: Bool
    let logger = Logger()

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    public init(_ modelName: String = "TodoModel", inMemory: Bool = false) {
        self.modelName = modelName
        self.inMemory = inMemory
    }

    @discardableResult
    func save(_ context: NSManagedObjectContext) -> Result<Bool, Error> {
        if context.hasChanges {
            do {
                try context.save()
                return .success(true)
            } catch {
                logger.debug("context save error: \(error.localizedDescription)")
                return .failure(error)
            }

        } else {
            return .success(true)
        }
    }

    enum WrappedIDError: Error {
        case noteObjectID
    }

    // 调用者需保证调用环境处在正确的 context 线程中
    func deleteObject(by wrappedID: WrappedID, context: NSManagedObjectContext) throws {
        guard case .objectID(let id) = wrappedID,
              let object = try? context.existingObject(with: id)
        else {
            throw WrappedIDError.noteObjectID
        }
        context.delete(object)
        try context.save()
    }
}

extension CoreDataStack {
    public static let shared = CoreDataStack()
    static let test = CoreDataStack(inMemory: true)
}

extension CoreDataStack {
    func _createNewGroup(_ sourceGroup: TodoGroup) async {
        await container.performBackgroundTask { [weak self] context in
            let group = C_Group(context: context)
            group.title = sourceGroup.title
            self?.save(context)
        }
    }

    func _updateGroup(_ sourceGroup: TodoGroup) async {
        await container.performBackgroundTask { [weak self] context in
            guard case .objectID(let id) = sourceGroup.id,
                  let group = try? context.existingObject(with: id) as? C_Group else {
                self?.logger.debug("can't get group by \(sourceGroup.id)")
                return
            }
            group.title = sourceGroup.title
            self?.save(context)
        }
    }

    func _deleteGroup(_ sourceGroup: TodoGroup) async {
        await container.performBackgroundTask { [weak self] context in
            do {
                try self?.deleteObject(by: sourceGroup.id, context: context)
            } catch {
                self?.logger.debug("can't get group by \(sourceGroup.id)")
            }
        }
    }
}
