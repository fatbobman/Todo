//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/23.
//

import Core
import Foundation
import SwiftUI

public struct TaskCellView: View {
    @ObservedObject var taskObject: AnyConvertibleValueObservableObject<TodoTask>
    let updateTask: (TodoTask) -> Void
    let deleteTaskButtonTapped: (TodoTask) -> Void
    let moveTaskButtonTapped: (TodoTask) -> Void
    let taskCellTapped: (TodoTask) -> Void

    init(
        taskObject: AnyConvertibleValueObservableObject<TodoTask>,
        updateTask: @escaping (TodoTask) -> Void,
        deleteTaskButtonTapped: @escaping (TodoTask) -> Void,
        moveTaskButtonTapped: @escaping (TodoTask) -> Void,
        taskCellTapped: @escaping (TodoTask) -> Void
    ) {
        self.taskObject = taskObject
        self.updateTask = updateTask
        self.deleteTaskButtonTapped = deleteTaskButtonTapped
        self.moveTaskButtonTapped = moveTaskButtonTapped
        self.taskCellTapped = taskCellTapped
    }

    public var body: some View {
        if let task = taskObject.wrappedValue {
            HStack {
                Button {
                    setCompleted(task)
                } label: {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .symbolRenderingMode(.multicolor)
                        .animation(.default, value: task.completed)
                }

                Button {
                    taskCellTapped(task)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(task.title)
                            .strikethrough(task.completed, color: .secondary)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .animation(.default, value: task.completed)
                        if task.memo != nil {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Memo")
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                    }
                }

                ZStack {
                    Image(systemName: task.priority == .high ? "star.fill" : "star")
                        .foregroundColor(task.priority == .high ? .blue : nil)
                        .onTapGesture {
                            setPriority(task)
                        }
                        .animation(.easeInOut, value: task.priority)
                }
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    deleteTaskButtonTapped(task)
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
            .swipeActions(edge: .leading) {
                Button {
                    setMyDay(task)
                } label: {
                    Image(systemName: "sun.max")
                }
                .tint(.orange)

                Button {
                    moveTaskButtonTapped(task)
                } label: {
                    Image(systemName: "rectangle.2.swap")
                }
                .tint(.green)
            }
        }
    }

    func setCompleted(_ task: TodoTask) {
        var task = task
        task.completed.toggle()
        updateTask(task)
    }

    func setPriority(_ task: TodoTask) {
        var task = task
        task.priority = task.priority == .high ? .standard : .high
        updateTask(task)
    }

    func setMyDay(_ task: TodoTask) {
        var task = task
        task.myDay.toggle()
        updateTask(task)
    }
}

#if DEBUG

private let previewTask = MockTask(.sample1).eraseToAny()
private let editTask: (TodoTask) async -> Void = { task in
    (previewTask._object as? MockTask)?.update(task)
}

struct TaskCellViewPreview: PreviewProvider {
    static var previews: some View {
        List {
            TaskCellView(
                taskObject: previewTask,
                updateTask: { task in
                    Task { await editTask(task) }
                },
                deleteTaskButtonTapped: { _ in },
                moveTaskButtonTapped: { _ in },
                taskCellTapped: { _ in }
            )
            TaskCellView(
                taskObject: MockTask(.sample3).eraseToAny(),
                updateTask: { _ in },
                deleteTaskButtonTapped: { _ in },
                moveTaskButtonTapped: { _ in },
                taskCellTapped: { _ in }
            )
            TaskCellView(
                taskObject: MockTask(.sample2).eraseToAny(),
                updateTask: { _ in },
                deleteTaskButtonTapped: { _ in },
                moveTaskButtonTapped: { _ in },
                taskCellTapped: { _ in }
            )
        }
        .onAppear {
            guard var task = previewTask.wrappedValue else { return }
            task.title = "协调器、持久化存储、托管上下文包装的官方实现。几乎无需调整任何核心代码。"
            task.memo = .sample1
            (previewTask._object as? MockTask)?.update(task)
        }
    }
}

#endif
