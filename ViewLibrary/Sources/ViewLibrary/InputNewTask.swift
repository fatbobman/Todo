//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/24.
//

import Core
import Foundation
import SwiftUI

public struct InputNewTaskView: View {
    let taskSource: TaskSource
    let createNewTask: (TodoTask, TaskSource) -> Void
    @State var taskText = ""
    @State var myDay: Bool
    @FocusState var editing: Bool

    public init(
        taskSource: TaskSource,
        createNewTask: @escaping (TodoTask, TaskSource) -> Void
    ) {
        self.taskSource = taskSource
        self.createNewTask = createNewTask
        if case .myDay = taskSource {
            _myDay = State(wrappedValue: true)
        } else {
            _myDay = State(wrappedValue: false)
        }
    }

    public var body: some View {
        ZStack {
            HStack(spacing: 15) {
                Button {
                    myDay.toggle()
                } label: {
                    HStack {
                        Image(systemName: myDay ? "sun.max.fill" : "sun.max")
                    }
                    .animation(.default, value: myDay)
                }
                .foregroundColor(myDay ? .orange : nil)
                .buttonStyle(.plain)
                TextField("内容介于 \(Configuration.titleLengthRange.rangeDescription) 个字符", text: $taskText)
                    .textFieldStyle(.roundedBorder)
                    .focused($editing)
                    .submitLabel(.done)
                    .onSubmit {
                        if allowToSubmit {
                            submit()
                        } else if !taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty  {
                            editing = true
                        }
                    }
                Button {
                    submit()
                } label: {
                    Text("Done")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!allowToSubmit)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
        }
        .background(Material.bar, ignoresSafeAreaEdges: .bottom)
        .scrollDismissesKeyboard(.immediately)
    }

    func submit() {
        let task = TodoTask(id: .string("createNewTask"), priority: .standard, createDate: .now, title: taskText, completed: false, myDay: myDay)
        createNewTask(task, taskSource)
        taskText = ""
        editing = false
    }

    var allowToSubmit: Bool {
        (Configuration.titleLengthRange).contains(taskText.count)
    }
}

#if DEBUG
struct InputNewTaskViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            List(0..<100) {
                Text("\($0)")
            }
            .safeAreaInset(edge: .bottom) {
                InputNewTaskView(
                    taskSource: .myDay,
                    createNewTask: { _, _ in }
                )
            }
        }
    }
}
#endif
