//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/29.
//

import ComposableArchitecture
import Core
import Foundation

public struct TaskEditorReducer: ReducerProtocol {
    public struct State: Equatable {
        var taskTobeDeleted: TodoTask?
        var editingMemoOfTask: TodoTask?
        var deleteConfirmAlert: AlertState<Action>?
    }

    public enum Action: Equatable {
        case deleteTaskButtonTapped(TodoTask)
        case editMemoButtonTapped(TodoTask)
        case updateTask(TodoTask)
        case deleteTask(TodoTask)
        case updateMemo(TodoTask, TaskMemo?)
        case dismissDeleteConfirmAlert
    }

    @Dependency(\.updateTask)
    var deleteTask

    @Dependency(\.updateTask)
    var updateTask

    @Dependency(\.updateMemo)
    var updateMemo

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .updateTask(let task):
                return .fireAndForget {
                    await updateTask(task)
                }
            case .deleteTask(let task):
                return .fireAndForget {
                    await deleteTask(task)
                }
            case .updateMemo(let task, let memo):
                return .fireAndForget {
                    await updateMemo(task, memo)
                }
            case .deleteTaskButtonTapped(let task):
                state.deleteConfirmAlert = AlertState(
                    title: TextState("Delete Task"),
                    primaryButton: .destructive(TextState("Confirm"), action: .send(.deleteTask(task))),
                    secondaryButton: .cancel(TextState("Cancel"))
                )
                return .none
            case .dismissDeleteConfirmAlert:
                state.deleteConfirmAlert = nil
                return .none
            case .editMemoButtonTapped(let task):
                state.editingMemoOfTask = task
                return .none
            }
        }
    }
}
