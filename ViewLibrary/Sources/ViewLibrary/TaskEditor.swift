//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/23.
//

import Core
import Foundation
import SwiftUI

public struct TaskEditorView: View {
    @Environment(\.getTaskObject) var getTaskObject
    @State var task: TodoTask
    let updateTask: (TodoTask) -> Void
    let deleteTaskButtonTapped: (TodoTask) -> Void
    let editMemoButtonTapped: (TodoTask) -> Void
    @FocusState var editTitle: Bool

    public init(
        task: TodoTask,
        updateTask: @escaping (TodoTask) -> Void,
        deleteTaskButtonTapped: @escaping (TodoTask) -> Void,
        editMemoButtonTapped: @escaping (TodoTask) -> Void
    ) {
        self._task = State(wrappedValue: task)
        self.deleteTaskButtonTapped = deleteTaskButtonTapped
        self.updateTask = updateTask
        self.editMemoButtonTapped = editMemoButtonTapped
    }

    public var body: some View {
        Form {
            Section {
                HStack {
                    Button {
                        setCompleted(task)
                    } label: {
                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                            .symbolRenderingMode(.multicolor)
                            .animation(.default, value: task.completed)
                    }

                    ZStack {
                        TextField("Add Task", text: $task.title, axis: .vertical)
                            .focused($editTitle)
                            .onTapGesture {
                                editTitle = true
                            }
                            .foregroundColor(editTitle ? nil : .clear)
                            .submitLabel(.continue)
                            .onSubmit {
                                editTitle = true
                            }
                            .onChange(of: task.title) { _ in
                                task.title = task.title.components(separatedBy: .newlines).joined()
                            }
                        if !editTitle {
                            Text(task.title)
                                .allowsHitTesting(false)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .strikethrough(task.completed, color: .secondary)
                    .font(.body)
                    .animation(.default, value: task.completed)

                    Button {
                        Task { setPriority(task) }
                    } label: {
                        Image(systemName: "star")
                            .symbolVariant(task.priority == .high ? .fill : .none)
                            .foregroundColor(task.priority == .high ? .blue : nil)
                            .animation(.default, value: task.priority)
                    }
                }

                // add to my day
                Button {
                    setMyDay(task)
                } label: {
                    HStack {
                        Image(systemName: task.myDay ? "sun.max.fill" : "sun.max")
                        Text("Add to My Day")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        Image(systemName: "xmark")
                            .font(.caption)
                            .opacity(task.myDay ? 1 : 0)
                    }
                    .animation(.default, value: task.myDay)
                }
                .foregroundColor(task.myDay ? .orange : nil)
            } header: {
                Text("between \(Configuration.titleLengthRange.rangeDescription) characters")
                    .font(.caption2)
                    .foregroundColor(!(Configuration.titleLengthRange).contains(task.title.count) ? .red : .clear)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Section("Memo") {
                Button {
                    editMemoButtonTapped(task)
                }
                label: {
                    if let memo = task.memo {
                        Text(memo.content)
                    } else {
                        Text("Add Memo")
                            .foregroundColor(.blue)
                    }
                }
            }
            .tint(.primary)
        }
        .buttonStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        deleteTaskButtonTapped(task)
                    } label: {
                        Image(systemName: "trash")
                    }
                    if editTitle {
                        Button {
                            setTitle(task)
                            editTitle = false
                        } label: {
                            Text("Done")
                        }
                        .disabled(!(Configuration.titleLengthRange).contains(task.title.count))
                    }
                }
                .animation(.easeInOut, value: editTitle)
            }
        }
        .task { @MainActor in
            guard let taskObject = await getTaskObject(task) else { return }
            task = taskObject.wrappedValue
            for await _ in taskObject.objectWillChange.values {
                task = taskObject.wrappedValue
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

    func setTitle(_ task: TodoTask) {
        updateTask(task)
    }
}

#if DEBUG
private let previewTask = MockTask(.sample1).eraseToAny()
private let editTask: (TodoTask) async -> Void = { task in
    (previewTask._object as? MockTask)?.update(task)
}

struct TaskEditorViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TaskEditorView(
                task: .sample3,
                updateTask: { task in
                    Task {
                        await editTask(task)
                    }
                },
                deleteTaskButtonTapped: { _ in },
                editMemoButtonTapped: { _ in }
            )
            .environment(\.getTaskObject) { _ in
                previewTask
            }
        }
    }
}
#endif
