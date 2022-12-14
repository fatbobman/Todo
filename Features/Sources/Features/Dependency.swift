//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/29.
//

import Core
import Dependencies
import Foundation

struct CreateNewGroupKey: DependencyKey {
    static var liveValue: @Sendable (TodoGroup) async -> Void = { _ in }
}

struct UpdateGroupKey: DependencyKey {
    static var liveValue: @Sendable (TodoGroup) async -> Void = { _ in }
}

struct DeleteGroupKey: DependencyKey {
    static var liveValue: @Sendable (TodoGroup) async -> Void = { _ in }
}

struct CreateNewTaskKey: DependencyKey {
    static var liveValue: @Sendable (TodoTask, TaskSource) async -> Void = { _, _ in }
}

struct UpdateTaskKey: DependencyKey {
    static var liveValue: @Sendable (TodoTask) async -> Void = { _ in }
}

struct DeleteTaskKey: DependencyKey {
    static var liveValue: @Sendable (TodoTask) async -> Void = { _ in }
}

struct MoveTaskKey: DependencyKey {
    static var liveValue: @Sendable (WrappedID, WrappedID) async -> Void = { _, _ in }
}

struct UpdateMemoKey: DependencyKey {
    static var liveValue: @Sendable (TodoTask, TaskMemo?) async -> Void = { _, _ in }
}

public extension DependencyValues {
    var createNewGroup: @Sendable (TodoGroup) async -> Void {
        get { self[CreateNewGroupKey.self] }
        set { self[CreateNewGroupKey.self] = newValue }
    }

    var updateGroup: @Sendable (TodoGroup) async -> Void {
        get { self[UpdateGroupKey.self] }
        set { self[UpdateGroupKey.self] = newValue }
    }

    var deleteGroup: @Sendable (TodoGroup) async -> Void {
        get { self[DeleteGroupKey.self] }
        set { self[DeleteGroupKey.self] = newValue }
    }

    var createNewTask: @Sendable (TodoTask, TaskSource) async -> Void {
        get { self[CreateNewTaskKey.self] }
        set { self[CreateNewTaskKey.self] = newValue }
    }

    var updateTask: @Sendable (TodoTask) async -> Void {
        get { self[UpdateTaskKey.self] }
        set { self[UpdateTaskKey.self] = newValue }
    }

    var deleteTask: @Sendable (TodoTask) async -> Void {
        get { self[DeleteTaskKey.self] }
        set { self[DeleteTaskKey.self] = newValue }
    }

    var moveTask: @Sendable (WrappedID, WrappedID) async -> Void {
        get { self[MoveTaskKey.self] }
        set { self[MoveTaskKey.self] = newValue }
    }

    var updateMemo: @Sendable (TodoTask, TaskMemo?) async -> Void {
        get { self[UpdateMemoKey.self] }
        set { self[UpdateMemoKey.self] = newValue }
    }
}
