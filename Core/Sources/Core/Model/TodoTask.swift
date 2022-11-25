//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/22.
//

import Foundation

public struct TodoTask: BaseValueProtocol {
    public let id: WrappedID
    public var priority: Priority
    public var createDate: Date
    public var title: String
    public var completed: Bool
    public var myDay: Bool
    public var memo: TaskMemo?

    public enum Priority: Int, Sendable, Equatable {
        case high = 2
        case standard = 1
    }

    public init(
        id: WrappedID,
        priority: Priority,
        createDate: Date,
        title: String,
        completed: Bool,
        myDay: Bool,
        memo: TaskMemo? = nil
    ) {
        self.id = id
        self.priority = priority
        self.createDate = createDate
        self.title = title
        self.completed = completed
        self.myDay = myDay
        self.memo = memo
    }
}

public struct TaskMemo: BaseValueProtocol {
    public let id: WrappedID
    public var content: String

    public init(id: WrappedID, content: String) {
        self.id = id
        self.content = content
    }
}

public struct TodoGroup: BaseValueProtocol {
    public let id: WrappedID
    public var title: String
    public var taskCount: Int

    public init(id: WrappedID, title: String, taskCount: Int) {
        self.id = id
        self.title = title
        self.taskCount = taskCount
    }
}

public extension TodoTask {
    static let placeHold = TodoTask(
        id: .string("placHoldTask"),
        priority: .high,
        createDate: Date(timeIntervalSince1970: 0),
        title: "由于 NavigationStack 的预加载机制会导致 toolbar 在切换时错位，用 placeHoldTask 避免使用 if let",
        completed: false,
        myDay: true
    )
}

#if DEBUG
public extension TodoTask {
    static let sample1 = TodoTask(
        id: .string("task1"),
        priority: .high,
        createDate: Date(timeIntervalSince1970: 0),
        title: "尽快吃饭",
        completed: false,
        myDay: true
    )

    static let sample2 = TodoTask(
        id: .string("task2"),
        priority: .high,
        createDate: Date(timeIntervalSince1970: 1),
        title: "早点睡觉",
        completed: false,
        myDay: false,
        memo: .sample1
    )

    static let sample3 = TodoTask(
        id: .string("task3"),
        priority: .high,
        createDate: Date(timeIntervalSince1970: 3),
        title: "监控血压",
        completed: true,
        myDay: true,
        memo: nil
    )
}

public extension TaskMemo {
    static let sample1 = TaskMemo(id: .string("memo1"), content: "hello world memo1")
    static let sample2 = TaskMemo(id: .string("memo2"), content: "hello world memo2")
}

public extension TodoGroup {
    static let sample1 = TodoGroup(id: .string("Group1"), title: "Group1", taskCount: 5)
    static let sample2 = TodoGroup(id: .string("Group2"), title: "Group2", taskCount: 5)
    static let sample3 = TodoGroup(id: .string("Group3"), title: "Group3", taskCount: 0)
}
#endif
