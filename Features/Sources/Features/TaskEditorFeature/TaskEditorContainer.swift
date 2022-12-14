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

public struct TaskEditorContainerView: View {
    let store: StoreOf<TaskEditorReducer>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<TaskEditorReducer>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TaskEditorView(
                task: viewStore.task,
                updateTask: { viewStore.send(.updateTask($0)) },
                deleteTaskButtonTapped: { _ in viewStore.send(.deleteTaskButtonTapped) },
                editMemoButtonTapped: { viewStore.send(.editMemoButtonTapped($0)) }
            )
            .alert(store.scope(state: \.deleteConfirmAlert), dismiss: TaskEditorReducer.Action.dismissDeleteConfirmAlert)
            .sheet(store.scope(state: \.editingMemoOfTask), dismissAction: .dismissMemoEditor) { store in
                WithViewStore(store, observe: { $0 }) { viewStore in
                    MemoEditor(
                        task: viewStore.state,
                        dismiss: { viewStore.send(.dismissMemoEditor) },
                        updateMemo: { viewStore.send(.updateMemo($0, $1)) }
                    )
                    .interactiveDismissDisabled(true)
                }
            }
            .onChange(of: viewStore.dismiss) { dismiss in
                if dismiss {
                    self.dismiss()
                }
            }
        }
    }
}

#if DEBUG
struct TaskEditorContainerPreviewRoot: View {
    @State var taskObject = MockTask(.sample1).eraseToAny()
    var body: some View {
        if let task = taskObject.wrappedValue {
            TaskEditorContainerView(
                store: .init(
                    initialState: .init(task: task),
                    reducer: TaskEditorReducer()
                        .dependency(\.deleteTask) { _ in }
                        .dependency(\.updateTask) { task in
                            (taskObject._object as? MockTask)?.update(task)
                        }
                        .dependency(\.updateMemo) { task, memo in
                            var task = task
                            task.memo = memo
                            (taskObject._object as? MockTask)?.update(task)
                        }
                )
            )
            .environment(\.getTaskObject) { _ in
                taskObject
            }
        }
    }
}

struct TaskEditorContainerPreview: PreviewProvider {
    static var previews: some View {
        TaskEditorContainerPreviewRoot()
    }
}
#endif
