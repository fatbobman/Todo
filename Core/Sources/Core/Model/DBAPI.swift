//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/22.
//

import Combine
import CoreData
import Foundation

public protocol DBAPI {
    /// 获取 Task FetchRequest
    var getTodoListRequest: @Sendable (TaskSource, TaskSortType) async -> NSFetchRequest<NSManagedObject>? { get }

    /// 获取 Group Request
    var getTodoGroupRequest: @Sendable () async -> NSFetchRequest<NSManagedObject>? { get }

    /// 获取可移动至的 Group Request
    var getMovableGroupListRequest: @Sendable (TodoTask) async -> NSFetchRequest<NSManagedObject>? { get }

    /// 获取 TodoTask Object
    var getTaskObject: @Sendable (TodoTask) async -> AnyConvertibleValueObservableObject<TodoTask>? { get }

    /// 跟踪 Group 中 task 数量的 AsyncPublisher
    var taskCount: @Sendable (TaskSource) async -> AsyncStream<Int> { get }

    /// 新建 Group
    var createNewGroup: @Sendable (TodoGroup) async -> Void { get }

    /// 编辑 List
    var updateGroup: @Sendable (TodoGroup) async -> Void { get }

    /// 删除 List
    var deleteGroup: @Sendable (TodoGroup) async -> Void { get }

    /// 新建 Task
    var createNewTask: @Sendable (TodoTask, TaskSource) async -> Void { get }

    /// 编辑 Task
    var updateTask: @Sendable (TodoTask) async -> Void { get }

    /// 删除 Task
    var deleteTask: @Sendable (TodoTask) async -> Void { get }

    /// 移动 Task ( task ID,target Group ID)
    var moveTask: @Sendable (WrappedID, WrappedID) async -> Void { get }

    /// 更新 Memo
    var updateMemo: @Sendable (TodoTask, TaskMemo?) async -> Void { get }
}
