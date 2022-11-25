//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/24.
//

import Core
import Foundation
import SwiftUI

struct MemoEditor: View {
    let task: TodoTask
    let dismiss: () -> Void
    let updateMemo: (TodoTask, TaskMemo?) -> Void
    let memo: TaskMemo?
    let mode: Mode
    @State var text: String
    @FocusState var editing: Bool

    enum Mode {
        case new, edit
    }

    init(task: TodoTask,
         dismiss: @escaping () -> Void,
         updateMemo: @escaping (TodoTask, TaskMemo?) -> Void) {
        self.task = task
        if let memo = task.memo {
            self.memo = memo
            mode = .edit
            _text = State(wrappedValue: memo.content)
        } else {
            self.memo = nil
            mode = .new
            _text = State(wrappedValue: "")
        }
        self.dismiss = dismiss
        self.updateMemo = updateMemo
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("请输入 Memo", text: $text, axis: .vertical)
                    .lineLimit(Configuration.memoLineLimit)
                    .focused($editing)
            }
            .navigationTitle(mode == .new ? "New Memo" : "Edit Memo")
            .toolbar{
                ToolbarItem{
                    Button{
                        submit()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
    }

    func submit() {
        let memo = text.isEmpty ? nil : TaskMemo(id: .string("createNewMemo"), content: text)
        if needToSubmit() {
            updateMemo(task, memo)
        }
        dismiss()
    }

    func needToSubmit() -> Bool {
        if case .edit = mode, let memo, text == memo.content { return false }
        if case .new = mode, text.isEmpty { return false }
        return true
    }
}

#if DEBUG
struct MemoEditorPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("")
                .sheet(isPresented: .constant(true)) {
                    MemoEditor(task: .sample1, dismiss: {}, updateMemo: { _, _ in })
                }
        }
    }
}
#endif
