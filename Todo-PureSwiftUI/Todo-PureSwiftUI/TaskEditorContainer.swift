//
//  TaskEditorContainer.swift
//  PureSwiftUI
//
//  Created by Yang Xu on 2022/11/25.
//

import Core
import Foundation
import SwiftUI
import ViewLibrary

struct TaskEditorContainerView: View {
    @Environment(\.deleteTask) private var deleteTaskEnv
    @Environment(\.updateTask) private var updateTaskEnv
    @Environment(\.dismiss) private var dismiss
    @Environment(\.updateMemo) private var updateMemoEnv
    @EnvironmentObject private var holder: SelectionHolder
    @State private var taskToBeDeleted: TodoTask?
    @State private var editingMemoOfTask: TodoTask?

    var body: some View {
        if let task = holder.selectedTask {
            TaskEditorView(
                task: task,
                updateTask: updateTask,
                deleteTaskButtonTapped: deleteTaskButtonTapped,
                editMemoButtonTapped: { editingMemoOfTask = $0 },
                dismissButtonTapped: {}
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
            .sheet(isPresented: .isPresented($editingMemoOfTask)) {
                if let editingMemoOfTask {
                    MemoEditor(
                        task: editingMemoOfTask,
                        dismiss: { self.editingMemoOfTask = nil },
                        updateMemo: updateMemo
                    )
                    .interactiveDismissDisabled(true)
                }
            }
        }
    }

    private func deleteTaskButtonTapped(task: TodoTask) {
        taskToBeDeleted = task
    }

    private func performDeleteTask() {
        guard let taskToBeDeleted else { return }
        Task { await deleteTaskEnv(taskToBeDeleted) }
        dismiss()
    }

    private func updateTask(task: TodoTask) {
        Task {
            await updateTaskEnv(task)
        }
    }

    private func updateMemo(task: TodoTask, memo: TaskMemo?) {
        Task {
            await updateMemoEnv(task, memo)
        }
    }
}
