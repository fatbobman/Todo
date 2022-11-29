//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/29.
//

import ComposableArchitecture
import Core
import Foundation

public struct GroupListReducer: ReducerProtocol {
    public struct State: Equatable {
        var taskList: TaskListReducer.State?
        var deleteConfirmAlert: AlertState<Action>?
        var groupEditMode: EditMode?

        public init() {}
    }

    public enum Action: Equatable {
        case deletedGroupButtonTapped(TodoGroup)
        case updateGroupButtonTapped(TodoGroup)
        case groupCellTapped(TaskSource)
        case createNewGroupButtonTapped
        case groupEditorDismiss
        case deleteConfirmAlertDismiss
        case deleteGroup(TodoGroup)
        case updateGroup(TodoGroup)
        case createGroup(TodoGroup)
        case taskListAction(TaskListReducer.Action)
    }

    @Dependency(\.deleteGroup)
    var deleteGroup

    @Dependency(\.updateGroup)
    var updateGroup

    @Dependency(\.createNewGroup)
    var createNewGroup

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .createNewGroupButtonTapped:
                state.groupEditMode = .new
                return .none
            case .groupCellTapped(let source):
                state.taskList = .init(taskSource: source)
                return .none
            case .groupEditorDismiss:
                state.groupEditMode = nil
                return .none
            case .deletedGroupButtonTapped(let group):
                state.deleteConfirmAlert = AlertState(
                    title: TextState("Delete \(group.title)"),
                    primaryButton: .destructive(TextState("Confirm"), action: .send(.deleteGroup(group))),
                    secondaryButton: .cancel(TextState("Cancel"))
                )
                return .none
            case .deleteConfirmAlertDismiss:
                state.deleteConfirmAlert = nil
                return .none
            case .updateGroupButtonTapped(let group):
                state.groupEditMode = .edit(group)
                return .none
            case .updateGroup(let group):
                return .fireAndForget {
                    await updateGroup(group)
                }
            case .deleteGroup(let group):
                return .fireAndForget {
                    await deleteGroup(group)
                }
            case .createGroup(let group):
                return .fireAndForget {
                    await createNewGroup(group)
                }
            case .taskListAction(let action):
                switch action {
                case .dismiss:
                    state.taskList = nil
                    return .none
                default:
                    return .none
                }
            }
        }
        .ifLet(\.taskList, action: /Action.taskListAction) {
            TaskListReducer()
        }
    }
}

public extension GroupListReducer {
    enum EditMode: Equatable {
        case new
        case edit(TodoGroup)
    }
}
