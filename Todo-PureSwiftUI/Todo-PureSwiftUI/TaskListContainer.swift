//
//  TaskListContainer.swift
//  PureSwiftUI
//
//  Created by Yang Xu on 2022/11/24.
//

import Core
import Foundation
import SwiftUI
import ViewLibrary

struct TaskListContainerView: View {
    @Environment(\.updateTask) private var updateTaskEnv
    @Environment(\.createNewTask) private var createNewTaskEnv
    @Environment(\.deleteTask) private var deleteTaskEnv
    @Environment(\.moveTask) private var moveTaskEnv

    @State private var taskToBeDeleted: TodoTask?
    @State private var taskToBeMoved: TodoTask?
    @AppStorage("TodoListSortType") private var sortType: TaskSortType = .title
    @EnvironmentObject private var holder: SelectionHolder

    var body: some View {
        if let taskSource = holder.selectedTaskSource {
            TaskListView(
                taskSource: taskSource,
                taskSortType: sortType,
                updateTask: updateTask,
                deleteTaskButtonTapped: deleteTaskButtonTapped,
                moveTaskButtonTapped: moveTaskButtonTapped,
                taskCellTapped: taskCellTapped
            )
            .safeAreaInset(edge: .bottom) {
                InputNewTaskView(
                    taskSource: taskSource,
                    createNewTask: createNewTask
                )
            }
            // 目前用 navigationTitle 有闪烁 bug
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    TaskSortButton(taskSortType: $sortType)
                }
            }
            .navigationTitle(taskListTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: .isPresented($taskToBeMoved)) {
                if let taskToBeMoved {
                    MoveTaskToNewGroupView(
                        task: taskToBeMoved,
                        dismiss: { self.taskToBeMoved = nil },
                        movableTaskTargetCellTapped: movableTaskTargetCellTapped
                    )
                }
            }
            .alert(
                "Delete Task",
                isPresented: .isPresented($taskToBeDeleted),
                actions: {
                    Button("Confirm", role: .destructive) {
                        performDeleteTask()
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: {
                    Text("Once deleted, data is irrecoverable")
                }
            )
            .navigationDestination(isPresented: .isPresented($holder.selectedTask)) {
                TaskEditorContainerView()
            }
        }
    }

    private var taskListTitle: String {
        switch holder.selectedTaskSource {
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

    private func deleteTaskButtonTapped(task: TodoTask) {
        taskToBeDeleted = task
    }

    private func performDeleteTask() {
        guard let taskToBeDeleted else { return }
        Task { await deleteTaskEnv(taskToBeDeleted) }
    }

    private func taskCellTapped(task: TodoTask) {
        holder.selectedTask = task
    }

    private func updateTask(task: TodoTask) {
        Task {
            await updateTaskEnv(task)
        }
    }

    private func createNewTask(task: TodoTask, taskSource: TaskSource) {
        Task {
            await createNewTaskEnv(task, taskSource)
        }
    }

    private func moveTaskButtonTapped(task: TodoTask) {
        taskToBeMoved = task
    }

    private func movableTaskTargetCellTapped(taskID: WrappedID, groupID: WrappedID) {
        Task { await moveTaskEnv(taskID, groupID) }
    }
}

#if DEBUG
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

struct TaskListContainerRootForPreview: View {
    @StateObject var dataSource = ListContainerDataSource()
    @State var id = UUID()

    var body: some View {
        NavigationStack {
            TaskListContainerView()
                .transformEnvironment(\.dataSource) {
                    guard var result = $0 as? ObjectsDataSource else { return }
                    result.unCompletedTasks = .mockObjects(.init(dataSource.unCompleted))
                    result.completedTasks = .mockObjects(.init(dataSource.completed))
                    $0 = result
                }
                .environment(\.deleteTask) { task in
                    await MainActor.run {
                        guard let index = dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return }
                        dataSource.tasks.remove(at: index)
                    }
                }
                .environment(\.updateTask) { task in
                    await MainActor.run {
                        guard let index = dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return }
                        (dataSource.tasks[index]._object as? MockTask)?.update(task)
                        id = UUID()
                    }
                }
                .environment(\.createNewTask) { task, _ in
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
//                .id(id) // 解决 preview 中，transformEnvironment 不刷新的问题
        }
    }
}

struct TaskListContainerPreview: PreviewProvider {
    @State static var selectedSourceHolder = SelectionHolder(selectedTaskSource: .all)
    static var previews: some View {
        TaskListContainerRootForPreview()
            .environmentObject(selectedSourceHolder)
    }
}
#endif
