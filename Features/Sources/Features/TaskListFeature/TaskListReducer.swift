//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/29.
//

import ComposableArchitecture
import Core
import Foundation
import SwiftUI

public struct TaskListReducer: ReducerProtocol {
    public struct State: Equatable {
        let taskSource: TaskSource
        var sortType: TaskSortType
        var taskToBeMoved: TodoTask?
        var taskEditor: TaskEditorReducer.State?
        var deleteConfirmAlert: AlertState<Action>?

        var taskListTitle: String {
            switch taskSource {
            case .all:
                return "All Tasks"
            case .completed:
                return "Completed Tasks"
            case .myDay:
                return "My Day Tasks"
            case .list(let group):
                return group.title
            default:
                return ""
            }
        }

        public init(taskSource: TaskSource) {
            self.taskSource = taskSource
            self.sortType = .title
        }
    }

    public enum Action: Equatable {
        case changeSortType(TaskSortType)
        case deleteTaskButtonTapped(TodoTask)
        case moveTaskButtonTapped(TodoTask)
        case taskCellTapped(TodoTask)
        case createNewTask(TodoTask, TaskSource)
        case updateTask(TodoTask)
        case deleteTask(TodoTask)
        case moveTask(WrappedID, WrappedID)
        case onAppear
        case dismissMovableTaskList
        case dismissDeleteConfirmAlert
        case taskEditorAction(TaskEditorReducer.Action)
        case dismiss
    }

    public init() {}

    @Dependency(\.createNewTask)
    var createNewTask

    @Dependency(\.updateTask)
    var updateTask

    @Dependency(\.deleteTask)
    var deleteTask

    @Dependency(\.moveTask)
    var moveTask

    private let sortTypeKey = "TodoListSortType"

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .changeSortType(let sortType):
                state.sortType = sortType
                return .fireAndForget {
                    UserDefaults.standard.set(sortType.rawValue, forKey: sortTypeKey)
                }
            case .deleteTaskButtonTapped(let task):
                state.deleteConfirmAlert = AlertState(
                    title: TextState("Delete Task"),
                    primaryButton: .destructive(TextState("Confirm"), action: .send(.deleteTask(task))),
                    secondaryButton: .cancel(TextState("Cancel"))
                )
                return .none
            case .moveTaskButtonTapped(let task):
                state.taskToBeMoved = task
                return .none
            case .taskCellTapped(let task):
                state.taskEditor = .init(task: task)
                return .none
            case .createNewTask(let task, let source):
                return .fireAndForget {
                    await createNewTask(task, source)
                }
            case .updateTask(let task):
                return .fireAndForget {
                    await updateTask(task)
                }
            case .deleteTask(let task):
                return .fireAndForget {
                    await deleteTask(task)
                }
            case .moveTask(let taskID, let sourceID):
                return .task {
                    await moveTask(taskID, sourceID)
                    return .dismissMovableTaskList
                }
            case .dismissMovableTaskList:
                state.taskToBeMoved = nil
                return .none
            case .dismissDeleteConfirmAlert:
                state.deleteConfirmAlert = nil
                return .none
            case .onAppear:
                return .task {
                    let saved = UserDefaults.standard.string(forKey: sortTypeKey) ?? TaskSortType.title.rawValue
                    let sortType = TaskSortType(rawValue: saved) ?? .title
                    return .changeSortType(sortType)
                }
            case .dismiss:
                return .none
            case .taskEditorAction:
                return .none
            }
        }
        .ifLet(\.taskEditor, action: /Action.taskEditorAction) {
            TaskEditorReducer()
        }
    }
}
