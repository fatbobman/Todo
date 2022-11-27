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
        ZStack(alignment: .top) {
            HStack(spacing: 15) {
                Button {
                    myDay.toggle()
                } label: {
                    HStack {
                        Image(systemName: myDay ? "sun.max.fill" : "sun.max")
                            .font(.title2)
                    }
                    .animation(.default, value: myDay)
                }
                .foregroundColor(myDay ? .orange : nil)
                .buttonStyle(.plain)
                TextField("between \(Configuration.titleLengthRange.rangeDescription) characters", text: $taskText)
                    .textFieldStyle(.roundedBorder)
                    .focused($editing)
                    .onSubmit {
                        if allowToSubmit {
                            submit()
                        } else {
                            taskText = ""
                        }
                    }
                Button {
                    submit()
                } label: {
                    Text("Done")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!allowToSubmit)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
        }
        .background(.regularMaterial.shadow(.drop(radius: 1)), ignoresSafeAreaEdges: .bottom)
    }

    func submit() {
        let task = TodoTask(
            id: .string("createNewTask"),
            priority: .standard,
            createDate: .now,
            title: taskText.trimmingCharacters(in: .whitespacesAndNewlines),
            completed: false,
            myDay: myDay
        )

        taskText = ""
        editing = false

        // 避免 List 与 键盘同时动画，改善因 safeArea 导致的列表地步刷新问题
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            createNewTask(task, taskSource)
        }
    }

    var allowToSubmit: Bool {
        (Configuration.titleLengthRange)
            .contains(taskText.trimmingCharacters(in: .whitespacesAndNewlines).count)
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
