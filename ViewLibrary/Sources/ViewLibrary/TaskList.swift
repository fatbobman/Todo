//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/24.
//

import Core
import Foundation
import SwiftUI

public struct TaskListView: View {
    @MockableFetchRequest(\ObjectsDataSource.unCompletedTasks) var tasks
    @MockableFetchRequest(\ObjectsDataSource.completedTasks) var completedTasks
    @Environment(\.getTodoListRequest) var getTodoListRequest
    let taskSource: TaskSource
    let taskSortType: TaskSortType
    let updateTask: (TodoTask) -> Void
    let deleteTaskButtonTapped: (TodoTask) -> Void
    let moveTaskButtonTapped: (TodoTask) -> Void
    let taskCellTapped: (TodoTask) -> Void

    public init(taskSource: TaskSource,
                taskSortType: TaskSortType,
                updateTask: @escaping (TodoTask) -> Void,
                deleteTaskButtonTapped: @escaping (TodoTask) -> Void,
                moveTaskButtonTapped: @escaping (TodoTask) -> Void,
                taskCellTapped: @escaping (TodoTask) -> Void) {
        self.taskSource = taskSource
        self.taskSortType = taskSortType
        self.updateTask = updateTask
        self.deleteTaskButtonTapped = deleteTaskButtonTapped
        self.moveTaskButtonTapped = moveTaskButtonTapped
        self.taskCellTapped = taskCellTapped
    }

    public var body: some View {
        List {
            ForEach(tasks) { task in
                TaskCellView(
                    taskObject: task,
                    updateTask: updateTask,
                    deleteTaskButtonTapped: deleteTaskButtonTapped,
                    moveTaskButtonTapped: moveTaskButtonTapped,
                    taskCellTapped: taskCellTapped
                )
            }
        }
        .task(id: taskSortType) { @MainActor in
            let request = await getTodoListRequest(taskSource, taskSortType)
            if let request {
                $tasks = request
            }
        }
    }
}

#if DEBUG
struct TaskListViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TaskListView(
                taskSource: .all,
                taskSortType: .title,
                updateTask: { _ in },
                deleteTaskButtonTapped: { _ in },
                moveTaskButtonTapped: { _ in },
                taskCellTapped: { _ in }
            )
            .toolbar {
                ToolbarItem {
                    TaskSortButton(taskSortType: .constant(.createDate))
                }
            }
        }
    }
}
#endif
