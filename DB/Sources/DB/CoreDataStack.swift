//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/26.
//

import Combine
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

    public var viewContext: NSManagedObjectContext {
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
    func _createNewTask(_ sourceTask: TodoTask, _ taskSource: TaskSource) async {
        await container.performBackgroundTask { [weak self] context in
            var group: C_Group?
            switch taskSource {
            case .all, .completed, .myDay, .moveableGroupList:
                break
            case .list(let sourceGroup):
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
    func _moveTask(_ sourceTaskID: WrappedID, _ sourceGroupID: WrappedID) async {
        await container.performBackgroundTask { [weak self] context in
            guard case .objectID(let taskID) = sourceTaskID,
                  let task = try? context.existingObject(with: taskID) as? C_Task else {
                self?.logger.error("can't get task by \(sourceTaskID)")
                return
            }
            guard case .objectID(let groupID) = sourceGroupID,
                  let group = try? context.existingObject(with: groupID) as? C_Group else {
                self?.logger.error("can't get group by \(sourceGroupID)")
                return
            }
            task.group = group
            self?.save(context)
        }
    }

    @Sendable
    func _updateMemo(_ sourceTask: TodoTask, _ sourceMemo: TaskMemo?) async {
        // 使用偷懒的方法解决 memo update 后的 Task 数据更新问题
        // memo == nil ,删除
        // memo != nil ,原来有替换，没有新增
        await container.performBackgroundTask { [weak self] context in
            guard case .objectID(let taskID) = sourceTask.id,
                  let task = try? context.existingObject(with: taskID) as? C_Task else {
                self?.logger.error("can't get task by \(sourceTask.id)")
                return
            }
            if let sourceMemo {
                if let memo = task.memo {
                    context.delete(memo)
                }
                let newMemo = C_Memo(context: context)
                newMemo.content = sourceMemo.content
                newMemo.task = task
            } else {
                task.memo = nil
            }
            self?.save(context)
        }
    }

    @Sendable
    func _getTaskObject(_ task: TodoTask) async -> AnyConvertibleValueObservableObject<TodoTask>? {
        return await MainActor.run { [weak self] in
            let context = self?.viewContext
            guard case .objectID(let id) = task.id,
                  let taskObject = try? context?.existingObject(with: id) as? C_Task else {
                self?.logger.error("can't get task by \(task.id)")
                return nil
            }
            return taskObject.eraseToAny()
        }
    }

    @Sendable
    func _getTodoListRequest(_ source: TaskSource, _ sortType: TaskSortType) async -> (unCompleted: NSFetchRequest<NSManagedObject>?, completed: NSFetchRequest<NSManagedObject>?) {
        await viewContext.perform { [weak self] in
            let completedRequest: NSFetchRequest<NSManagedObject>?
            let unCompletedRequest: NSFetchRequest<NSManagedObject>?

            let sortDescriptions: [NSSortDescriptor]
            switch sortType {
            case .title:
                sortDescriptions = [
                    .init(key: #keyPath(C_Task.title), ascending: true),
                    .init(key: #keyPath(C_Task.createDate), ascending: false),
                    .init(key: #keyPath(C_Task.priority), ascending: false)
                ]
            case .createDate:
                sortDescriptions = [
                    .init(key: #keyPath(C_Task.createDate), ascending: false),
                    .init(key: #keyPath(C_Task.title), ascending: true),
                    .init(key: #keyPath(C_Task.priority), ascending: false)
                ]
            case .priority:
                sortDescriptions = [
                    .init(key: #keyPath(C_Task.priority), ascending: false),
                    .init(key: #keyPath(C_Task.createDate), ascending: false),
                    .init(key: #keyPath(C_Task.title), ascending: true)
                ]
            }

            var completedPredicate: NSPredicate?
            var unCompletedPredicate: NSPredicate?

            switch source {
            case .all:
                completedPredicate = .init(format: "completed = YES")
                unCompletedPredicate = .init(format: "completed = NO")
            case .completed:
                completedPredicate = .init(format: "completed = TRUE")
                unCompletedPredicate = nil
            case .myDay:
                completedPredicate = .init(format: "completed = YES And myDay = YES")
                unCompletedPredicate = .init(format: "completed = NO And myDay = YES")
            case .list(let group):
                guard case .objectID(let groupID) = group.id,
                      let groupObject = try? self?.viewContext.existingObject(with: groupID) as? C_Group else {
                    self?.logger.error("can't get group by \(group.id)")
                    return (unCompleted: nil, completed: nil)
                }
                completedPredicate = .init(format: "completed = YES And group = %@", groupObject)
                unCompletedPredicate = .init(format: "completed = NO And group = %@", groupObject)
            case .moveableGroupList:
                fatalError("The call to moveableGroupList should not occur")
            }

            completedRequest = NSFetchRequest<NSManagedObject>(entityName: "C_Task")
            unCompletedRequest = NSFetchRequest<NSManagedObject>(entityName: "C_Task")

            completedRequest?.predicate = completedPredicate
            completedRequest?.sortDescriptors = sortDescriptions

            unCompletedRequest?.sortDescriptors = sortDescriptions
            if source != .completed {
                unCompletedRequest?.predicate = unCompletedPredicate
            } else {
                // 不获取任何数据
                unCompletedRequest?.predicate = NSPredicate(value: false)
            }
            return (unCompleted: unCompletedRequest, completed: completedRequest)
        }
    }

    @Sendable
    func _getTodoGroupRequest() async -> NSFetchRequest<NSManagedObject>? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        return request
    }

    @Sendable
    func _getMovableGroupListRequest(_ task: TodoTask) async -> NSFetchRequest<NSManagedObject>? {
        await viewContext.perform { [weak self] in
            guard case .objectID(let taskID) = task.id,
                  let taskObject = try? self?.viewContext.existingObject(with: taskID) as? C_Task else {
                self?.logger.debug("can't get movable group list by \(task.id)")
                return nil
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "C_Group")
            request.sortDescriptors = [.init(key: "title", ascending: true)]
            if let groupObject = taskObject.group {
                request.predicate = NSPredicate(format: "self != %@", groupObject)
            }
            return request
        }
    }

    @Sendable
    func _taskCount(_ source: TaskSource) async -> AsyncStream<Int> {
        let request = NSFetchRequest<NSNumber>(entityName: "C_Task")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        request.resultType = .countResultType
        switch source {
        case .all:
            request.predicate = nil
        case .myDay:
            request.predicate = NSPredicate(format: "myDay = YES")
        case .completed:
            request.predicate = NSPredicate(format: "completed = YES")
        default:
            fatalError("Only all, Day, completed can generate count publisher")
        }

        let bgContext = self.container.newBackgroundContext()

        let countStream: AsyncStream<Int> = AsyncStream { continuation in
            Task {
                let count = await bgContext.perform {
                    (try? bgContext.fetch(request).first)?.intValue ?? 0
                }
                continuation.yield(count)
                for await _ in NotificationCenter.default.publisher(for: .taskDidSave).values where !Task.isCancelled {
                    let count = await bgContext.perform {
                        (try? bgContext.fetch(request).first)?.intValue ?? 0
                    }
                    continuation.yield(count)
                }
            }
        }

        return countStream
    }
}

extension CoreDataStack: DBAPI {
    public var createNewTask: @Sendable (Core.TodoTask, Core.TaskSource) async -> Void {
        _createNewTask
    }

    public var getTodoListRequest: @Sendable (Core.TaskSource, Core.TaskSortType) async ->
        (unCompleted: NSFetchRequest<NSManagedObject>?, completed: NSFetchRequest<NSManagedObject>?) {
        _getTodoListRequest
    }

    public var getTodoGroupRequest: @Sendable () async -> NSFetchRequest<NSManagedObject>? {
        _getTodoGroupRequest
    }

    public var getMovableGroupListRequest: @Sendable (Core.TodoTask) async -> NSFetchRequest<NSManagedObject>? {
        _getMovableGroupListRequest
    }

    public var getTaskObject: @Sendable (Core.TodoTask) async -> Core.AnyConvertibleValueObservableObject<Core.TodoTask>? {
        _getTaskObject
    }

    public var taskCount: @Sendable (Core.TaskSource) async -> AsyncStream<Int> {
        _taskCount
    }

    public var createNewGroup: @Sendable (Core.TodoGroup) async -> Void {
        _createNewGroup
    }

    public var updateGroup: @Sendable (Core.TodoGroup) async -> Void {
        _updateGroup
    }

    public var deleteGroup: @Sendable (Core.TodoGroup) async -> Void {
        _deleteGroup
    }

    public var updateTask: @Sendable (Core.TodoTask) async -> Void {
        _updateTask
    }

    public var deleteTask: @Sendable (Core.TodoTask) async -> Void {
        _deleteTask
    }

    public var moveTask: @Sendable (WrappedID, WrappedID) async -> Void {
        _moveTask
    }

    public var updateMemo: @Sendable (Core.TodoTask, Core.TaskMemo?) async -> Void {
        _updateMemo
    }
}
