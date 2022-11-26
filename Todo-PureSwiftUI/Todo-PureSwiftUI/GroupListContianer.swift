//
//  GroupListContianer.swift
//  PureSwiftUI
//
//  Created by Yang Xu on 2022/11/24.
//

import Core
import Foundation
import SwiftUI
import ViewLibrary

struct GroupListContainerView: View {
    @Environment(\.deleteGroup) private var deleteGroupEnv
    @Environment(\.updateGroup) private var updateGroupEnv
    @Environment(\.createNewGroup) private var createNewGroupEnv

    @State private var groupEditMode: EditMode?
    @State private var groupToBeDeleted: TodoGroup?
    // navigationDestination(isPresented:) 会创建一个新的上下文，该上下文对视图中的支持暂时有问题
    // 会导致导航后数据出现不同不的情况。将数据保存在视图外并传递引用才可以解决这个问题
    @EnvironmentObject private var sourceHolder: SelectionHolder

    var body: some View {
        NavigationStack {
            GroupListView(
                deletedGroupButtonTapped: deletedGroupButtonTapped,
                updateGroupButtonTapped: updateGroupButtonTapped,
                groupCellTapped: groupCellTapped,
                createNewGroupButtonTapped: createNewGroupButtonTapped
            )
            .navigationDestination(isPresented: .isPresented($sourceHolder.selectedTaskSource)) {
                TaskListContainerView()
            }
            .alert(
                groupEditMode == .new ? "New Group" : "Edit Group",
                isPresented: .isPresented($groupEditMode)
            ) {
                if case .edit(let group) = groupEditMode {
                    ModifierGroupView(group: group, perform: performUpdateGroup)
                } else {
                    ModifierGroupView(group: nil, perform: performUpdateGroup)
                }
            }
            .alert(
                "Delete \(groupToBeDeleted?.title ?? "")",
                isPresented: .isPresented($groupToBeDeleted),
                actions: {
                    Button("Confirm", role: .destructive) {
                        performDeleteGroup()
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: {
                    Text("Once deleted, data is irrecoverable")
                }
            )
        }
    }

    private func updateGroupButtonTapped(group: TodoGroup) {
        groupEditMode = .edit(group)
    }

    private func createNewGroupButtonTapped() {
        groupEditMode = .new
    }

    private func groupCellTapped(taskSource: TaskSource) {
        sourceHolder.selectedTaskSource = taskSource
    }

    private func deletedGroupButtonTapped(group: TodoGroup) {
        groupToBeDeleted = group
    }

    private func performUpdateGroup(group: TodoGroup) {
        guard !group.title.isEmpty else { return }
        Task { await updateGroupEnv(group) }
    }

    private func performDeleteGroup() {
        Task {
            if let groupToBeDeleted {
                await deleteGroupEnv(groupToBeDeleted)
            }
        }
    }

    enum EditMode: Equatable {
        case new
        case edit(TodoGroup)
    }
}

#if DEBUG

private var groups: [AnyConvertibleValueObservableObject<TodoGroup>] = [
    MockGroup(.sample1).eraseToAny(),
    MockGroup(.sample2).eraseToAny(),
    MockGroup(.sample3).eraseToAny()
]

struct GroupListContainerViewPreview: PreviewProvider {
    @State static var selectedSourceHolder = SelectionHolder(selectedTaskSource: .all)
    static var previews: some View {
        GroupListContainerView()
            .environmentObject(selectedSourceHolder)
            .transformEnvironment(\.dataSource) {
                $0.groups = .mockObjects(.init(
                    groups
                ))
            }
            .environment(\.updateGroup) { group in
                if group.id == .string("createNewGroup") {
                    let newGroup = TodoGroup(id: .uuid(UUID()), title: group.title, taskCount: 0)
                    groups.append(MockGroup(newGroup).eraseToAny())
                }
                guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
                (groups[index]._object as? MockGroup)?.title = group.title
            }
            .environment(\.deleteGroup) { group in
                guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
                groups.remove(at: index)
            }
            .environment(\.taskCount, mockCountStream)
    }
}

import Combine
@Sendable
func mockCountStream(taskSource: TaskSource) async -> AsyncStream<Int> {
    AsyncStream<Int> { c in
        Task {
            let publiser = Timer.publish(every: 2, on: .main, in: .default)
                .autoconnect()
                .map { _ in Int.random(in: 0...20) }
                .prepend(3)

            for await _ in publiser.values where !Task.isCancelled {
                c.yield(Int.random(in: 3...15))
            }
        }
    }
}
#endif
