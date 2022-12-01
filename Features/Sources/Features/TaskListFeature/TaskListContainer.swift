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
import ViewLibrary

public struct TaskListContainerView: View {
    let store: StoreOf<TaskListReducer>

    public init(store: StoreOf<TaskListReducer>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TaskListView(
                taskSource: viewStore.taskSource,
                taskSortType: viewStore.sortType,
                updateTask: { viewStore.send(.updateTask($0)) },
                deleteTaskButtonTapped: { viewStore.send(.deleteTaskButtonTapped($0)) },
                moveTaskButtonTapped: { viewStore.send(.moveTaskButtonTapped($0)) },
                taskCellTapped: { viewStore.send(.taskCellTapped($0)) }
            )
            .safeAreaInset(edge: .bottom) {
                InputNewTaskView(
                    taskSource: viewStore.taskSource,
                    createNewTask: { viewStore.send(.createNewTask($0, $1)) }
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    TaskSortButton(
                        taskSortType: viewStore.binding(
                            get: \.sortType,
                            send: { .changeSortType($0) }
                        )
                    )
                }
            }
            .navigationTitle(viewStore.taskListTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(store.scope(state: \.taskToBeMoved), dismissAction: .dismissMovableTaskList) { store in
                WithViewStore(store) { viewStore in
                    MoveTaskToNewGroupView(
                        task: viewStore.state,
                        dismiss: { viewStore.send(.dismissMovableTaskList) },
                        movableTaskTargetCellTapped: { viewStore.send(.moveTask($0, $1)) }
                    )
                }
            }
            .alert(store.scope(state: \.deleteConfirmAlert), dismiss: .dismissDeleteConfirmAlert)
            .navigationDestination(store.scope(state: \.taskEditor, action: TaskListReducer.Action.taskEditorAction), dismissAction: .dismiss) { store in
                TaskEditorContainerView(store: store)
            }
        }
    }
}

#if DEBUG
struct TaskListContainerViewPreviewRoot: View {
    @StateObject var dataSource = ListContainerDataSource()
    @State var id = UUID()
    var body: some View {
        TaskListContainerView(
            store: .init(
                initialState: .init(taskSource: .all),
                reducer: TaskListReducer()
                    .dependency(\.deleteTask) { task in
                        await MainActor.run {
                            guard let index = dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return }
                            dataSource.tasks.remove(at: index)
                        }
                    }
                    .dependency(\.updateTask) { task in
                        await MainActor.run {
                            guard let index = dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return }
                            (dataSource.tasks[index]._object as? MockTask)?.update(task)
                            id = UUID()
                        }
                    }
                    .dependency(\.createNewTask) { task, _ in
                        await MainActor.run {
                            let newTask: TodoTask = .init(
                                id: .uuid(UUID()),
                                priority: task.priority,
                                createDate: task.createDate,
                                title: task.title,
                                completed: task.completed,
                                myDay: task.myDay
                            )
                            dataSource.tasks.append(MockTask(newTask).eraseToAny())
                        }
                    }
            )
        )
        .transformEnvironment(\.dataSource) {
            guard var result = $0 as? ObjectsDataSource else { return }
            result.unCompletedTasks = .mockObjects(.init(dataSource.unCompleted))
            result.completedTasks = .mockObjects(.init(dataSource.completed))
            $0 = result
        }
        .id(id)
    }
}

final class ListContainerDataSource: ObservableObject {
    @Published var tasks = [
        MockTask(.sample1).eraseToAny(),
        MockTask(.sample2).eraseToAny(),
        MockTask(.sample3).eraseToAny()
    ]

    var completed: [AnyConvertibleValueObservableObject<TodoTask>] {
        tasks.filter { $0.wrappedValue!.completed }
    }

    var unCompleted: [AnyConvertibleValueObservableObject<TodoTask>] {
        tasks.filter { !$0.wrappedValue!.completed }
    }

    static let share = ListContainerDataSource()
}

struct TaskListContainerViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TaskListContainerViewPreviewRoot()
        }
    }
}

#endif
