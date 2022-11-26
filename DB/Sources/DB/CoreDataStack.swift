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

        let container = NSPersistentContainer(
            name: modelName,
            managedObjectModel: model
        )

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null/")
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

    public init(
        _ modelName: String = "TodoModel",
        inMemory: Bool = false
    ) {
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
    static var test: CoreDataStack {
        CoreDataStack(inMemory: true)
    }
}

extension CoreDataStack {
    @Sendable
    func _createNewGroup(_ sourceGroup: TodoGroup) async {
        await container.performBackgroundTask { [weak self] context in
            let group = C_Group(context: context)
            group.title = sourceGroup.title
            self?.save(context)
        }
    }

    @Sendable
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

    @Sendable
    func _deleteGroup(_ sourceGroup: TodoGroup) async {
        await container.performBackgroundTask { [weak self] context in
            do {
                try self?.deleteObject(by: sourceGroup.id, context: context)
            } catch {
                self?.logger.debug("can't get group by \(sourceGroup.id)")
            }
        }
    }

    @Sendable
    func _createNewTask(_ sourceTask: TodoTask, _ sourceGroup: TodoGroup?) async {
        await container.performBackgroundTask { [weak self] context in
            var group: C_Group?
            if let sourceGroup {
                if case .objectID(let groupID) = sourceGroup.id,
                   let tempGroup = try? context.existingObject(with: groupID) as? C_Group {
                    group = tempGroup
                } else {
                    self?.logger.error("can't get group by \(sourceGroup.id)")
                    return
                }
            }
            let task = C_Task(context: context)
            task.title = sourceTask.title
            task.createDate = .now
            task.group = group
            task.memo = nil
            task.completed = sourceTask.completed
            task.myDay = sourceTask.myDay
            task.priority = Int16(sourceTask.priority.rawValue)
            self?.save(context)
        }
    }

    @Sendable
    func _updateTask(_ sourceTask: TodoTask) async {
        await container.performBackgroundTask { [weak self] context in
            guard case .objectID(let taskID) = sourceTask.id,
                  let task = try? context.existingObject(with: taskID) as? C_Task else {
                self?.logger.error("can't get task by \(sourceTask.id)")
                return
            }
            task.priority = Int16(sourceTask.priority.rawValue)
            task.title = sourceTask.title
            task.completed = sourceTask.completed
            task.myDay = sourceTask.myDay
            self?.save(context)
        }
    }

    @Sendable
    func _deleteTask(_ sourceTask: TodoTask) async {
        await container.performBackgroundTask { [weak self] context in
            do {
                try self?.deleteObject(by: sourceTask.id, context: context)
            } catch {
                self?.logger.debug("can't get task by \(sourceTask.id)")
            }
        }
    }

    @Sendable
    func _moveTask(_ sourceTask: TodoTask, _ sourceGroup: TodoGroup) async {
        await container.performBackgroundTask { [weak self] context in
            guard case .objectID(let taskID) = sourceTask.id,
                  let task = try? context.existingObject(with: taskID) as? C_Task else {
                self?.logger.error("can't get task by \(sourceTask.id)")
                return
            }
            guard case .objectID(let groupID) = sourceGroup.id,
                  let group = try? context.existingObject(with: groupID) as? C_Group else {
                self?.logger.error("can't get group by \(sourceGroup.id)")
                return
            }
            task.group = group
            self?.save(context)
        }
    }
}
