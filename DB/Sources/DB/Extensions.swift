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
        .init(id: id, content: content ?? "")
    }
}

extension C_Group: ConvertibleValueObservableObject {
    public var id: WrappedID {
        .objectID(objectID)
    }

    public func convertToValueType() -> TodoGroup {
        .init(
            id: id,
            title: title ?? "",
            taskCount: tasks?.count ?? 0
        )
    }
}

extension C_Task: ConvertibleValueObservableObject {
    public var id: WrappedID {
        .objectID(objectID)
    }

    public func convertToValueType() -> TodoTask {
        .init(
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

public extension Notification.Name {
    static let taskDidSave = Notification.Name("taskDidSave")
}

public extension C_Task {
    override func didSave() {
        super.didSave()
        NotificationCenter.default.post(name: .taskDidSave, object: nil)
    }
}
