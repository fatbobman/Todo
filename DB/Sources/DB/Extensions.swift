//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/26.
//

import Core
import CoreData
import Foundation

extension C_Memo: ConvertibleValueObservableObject {
    public var id: WrappedID {
        .objectID(objectID)
    }

    public func convertToValueType() -> TaskMemo {
        guard let context = managedObjectContext else {
            fatalError("Must be run in a managed environment")
        }
        return context.performAndWait {
            TaskMemo(id: id, content: content ?? "")
        }
    }
}

extension C_Group: ConvertibleValueObservableObject {
    public var id: WrappedID {
        .objectID(objectID)
    }

    public func convertToValueType() -> TodoGroup {
        guard let context = managedObjectContext else {
            fatalError("Must be run in a managed environment")
        }
        return context.performAndWait {
            TodoGroup(
                id: id,
                title: title ?? "",
                taskCount: tasks?.count ?? 0
            )
        }
    }
}

extension C_Task: ConvertibleValueObservableObject {
    public var id: WrappedID {
        .objectID(objectID)
    }

    public func convertToValueType() -> TodoTask {
        guard let context = managedObjectContext else {
            fatalError("Must be run in a managed environment")
        }
        return context.performAndWait {
            TodoTask(
                id: id,
                priority: .init(rawValue: Int(priority)) ?? .standard,
                createDate: createDate ?? .distantPast,
                title: title ?? "",
                completed: completed,
                myDay: myDay,
                memo: memo?.convertToValueType()
            )
        }
    }
}

public extension Notification.Name {
    static let taskDidSave = Notification.Name("taskDidSave")
}

public extension C_Task {
    override func didSave() {
        super.didSave()
        NotificationCenter.default.post(name: .taskDidSave, object: nil)
    }
}

extension NSManagedObjectContext {
    @discardableResult
    func performAndWait<T>(_ block: () throws -> T) throws -> T {
        var result: Result<T, Error>?
        performAndWait {
            result = Result { try block() }
        }
        return try result!.get()
    }

    @discardableResult
    func performAndWait<T>(_ block: () -> T) -> T {
        var result: T?
        performAndWait {
            result = block()
        }
        return result!
    }
}
