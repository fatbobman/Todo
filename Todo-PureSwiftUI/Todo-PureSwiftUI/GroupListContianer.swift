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
    @State private var selectedTaskSource: TaskSource?

    var body: some View {
        NavigationStack {
            GroupListView(
                deletedGroupButtonTapped: deletedGroupButtonTapped,
                updateGroupButtonTapped: updateGroupButtonTapped,
                groupCellTapped: groupCellTapped,
                createNewGroupButtonTapped: createNewGroupButtonTapped
            )
            .navigationDestination(isPresented: .isPresented($selectedTaskSource)) {
                // 用 if let selectedTaskSource 会出现 Toolbar 闪烁的情况，改用 ??
                TaskListContainerView(taskSource: selectedTaskSource ?? .all)
                    .id(selectedTaskSource == .myDay) // 解决因为预创建实例，导致的视图 body 值不正确的问题
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
        selectedTaskSource = taskSource
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
    static var previews: some View {
        GroupListContainerView()
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
            .environment(\.taskCount, mockCountPublisher)
    }
}

import Combine
@Sendable
func mockCountPublisher(taskSource: TaskSource) async -> AsyncPublisher<AnyPublisher<Int, Never>> {
    Timer.TimerPublisher(interval: 1, runLoop: .main, mode: .default).autoconnect()
        .map { _ in Int.random(in: 10...20) }
        .prepend(Int.random(in: 1...4))
        .eraseToAnyPublisher()
        .values
}
#endif
