//
//  TaskEditorContainer.swift
//  PureSwiftUI
//
//  Created by Yang Xu on 2022/11/25.
//

import Foundation
import SwiftUI
import Core
import ViewLibrary

struct TaskEditorContainerView:View {
    @Environment(\.deleteTask) private var deleteTaskEnv
    @Environment(\.updateTask) private var updateTaskEnv
    @Environment(\.dismiss) private var dismiss

    let task:TodoTask

    @State private var taskToBeDeleted: TodoTask?
    var body: some View {
        TaskEditorView(
            task: task,
            updateTask: updateTask,
            deleteTaskButtonTapped: deleteTaskButtonTapped,
            editMemoButtonTapped: { _ in },
            dismissButtonTapped: {  }
        )
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
    }

    private func deleteTaskButtonTapped(task: TodoTask) {
        taskToBeDeleted = task
    }

    private func performDeleteTask() {
        guard let taskToBeDeleted else { return }
        dismiss()
        Task { await deleteTaskEnv(taskToBeDeleted) }
    }

    private func updateTask(task: TodoTask) {
        Task {
            await updateTaskEnv(task)
        }
    }

}
