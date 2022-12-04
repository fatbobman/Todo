//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/22.
//

import Combine
import CoreData
import Foundation
import SwiftUI

public enum TaskSortType: String, Equatable, CaseIterable, Identifiable {
    case title = "Title"
    case createDate = "Create Date"
    case priority = "Priority"
    case completed = "Completed"

    public var id: Self {
        self
    }
}

public enum TaskSource: Equatable {
    case all
    case myDay
    case completed
    case list(TodoGroup)
    case moveableGroupList(WrappedID)
}

/// 根据 TaskSource、TaskSortType 返回所需的 NSFetchRequest
/// 会返回两个 Request （ unCompleted , completed ）
public struct TodoListRequestKey: EnvironmentKey {
    public static var defaultValue: @Sendable (TaskSource, TaskSortType) async -> NSFetchRequest<NSManagedObject>? = { _, _ in
        print("Get todo list request not implement")
        return nil
    }
}

public struct MovableGroupListRequestKey: EnvironmentKey {
    public static var defaultValue: @Sendable (TodoTask) async -> NSFetchRequest<NSManagedObject>? = { _ in
        print("movable group list request not implement")
        return nil
    }
}

public struct TodoGroupRequestKey: EnvironmentKey {
    public static var defaultValue: @Sendable () async -> NSFetchRequest<NSManagedObject>? = { nil }
}

public struct GetTaskObjectKey: EnvironmentKey {
    public static var defaultValue: @Sendable (TodoTask) async -> AnyConvertibleValueObservableObject<TodoTask>? = { _ in nil }
}

public struct TaskCountKey: EnvironmentKey {
    public static var defaultValue: @Sendable (TaskSource) async -> AsyncStream<Int> = { taskSource in
        var result = 0
        switch taskSource {
        case .completed:
            result = 5
        case .myDay:
            result = 10
        case .all:
            result = 30
        default:
            fatalError("only support 'all','myDay' and 'finished'")
        }
        return AsyncStream<Int> { c in
            c.yield(result)
        }
    }
}

public extension EnvironmentValues {
    var getTodoListRequest: @Sendable (TaskSource, TaskSortType) async -> NSFetchRequest<NSManagedObject>? {
        get { self[TodoListRequestKey.self] }
        set { self[TodoListRequestKey.self] = newValue }
    }

    var getTodoGroupRequest: @Sendable () async -> NSFetchRequest<NSManagedObject>? {
        get { self[TodoGroupRequestKey.self] }
        set { self[TodoGroupRequestKey.self] = newValue }
    }

    var getTaskObject: @Sendable (TodoTask) async -> AnyConvertibleValueObservableObject<TodoTask>? {
        get { self[GetTaskObjectKey.self] }
        set { self[GetTaskObjectKey.self] = newValue }
    }

    var getMovableGroupListRequest: @Sendable (TodoTask) async -> NSFetchRequest<NSManagedObject>? {
        get { self[MovableGroupListRequestKey.self] }
        set { self[MovableGroupListRequestKey.self] = newValue }
    }

    var taskCount: @Sendable (TaskSource) async -> AsyncStream<Int> {
        get { self[TaskCountKey.self] }
        set { self[TaskCountKey.self] = newValue }
    }
}
