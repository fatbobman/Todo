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
    @EnvironmentObject private var holder: SelectionHolder

    var body: some View {
        NavigationStack {
            GroupListView(
                deletedGroupButtonTapped: deletedGroupButtonTapped,
                updateGroupButtonTapped: updateGroupButtonTapped,
                groupCellTapped: groupCellTapped,
                createNewGroupButtonTapped: createNewGroupButtonTapped
            )
            .navigationDestination(isPresented: .isPresented($holder.selectedTaskSource)) {
                TaskListContainerView()
            }
            .alert(
                groupEditMode == .new ? "New Group" : "Edit Group",
                isPresented: .isPresented($groupEditMode)
            ) {
                if case .edit(let group) = groupEditMode {
                    ModifierGroupView(
                        group: group,
                        perform: performUpdateGroup
                    )
                } else {
                    ModifierGroupView(
                        group: nil,
                        perform: performCreateNewGroup
                    )
                }
            }
            .alert(
                "Delete \(groupToBeDeleted?.title ?? "")",
                isPresented: .isPresented($groupToBeDeleted),
                actions: {
                    Button("Confirm", role: .destructive) {
                        performDeleteGroup(groupToBeDeleted)
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
        holder.selectedTaskSource = taskSource
    }

    private func deletedGroupButtonTapped(group: TodoGroup) {
        groupToBeDeleted = group
    }

    private func performUpdateGroup(group: TodoGroup) {
        guard !group.title.isEmpty else { return }
        Task { await updateGroupEnv(group) }
    }

    private func performDeleteGroup(_ group: TodoGroup?) {
        Task {
            if let group {
                await deleteGroupEnv(group)
            }
        }
    }

    private func performCreateNewGroup(group: TodoGroup) {
        guard !group.title.isEmpty else { return }
        Task { await createNewGroupEnv(group) }
    }

    enum EditMode: Equatable {
        case new
        case edit(TodoGroup)
    }
}

#if DEBUG

struct GroupListContainerViewPreviewRoot: View {
    @State var groups: [AnyConvertibleValueObservableObject<TodoGroup>] = [
        MockGroup(.sample1).eraseToAny(),
        MockGroup(.sample2).eraseToAny(),
        MockGroup(.sample3).eraseToAny()
    ]
    @StateObject var dataSource = ListContainerDataSource()
    @State var id = UUID()
    @StateObject var holder = SelectionHolder()
    var body: some View {
        NavigationStack {
            GroupListContainerView()
        }
        .environmentObject(holder)
        .transformEnvironment(\.dataSource) {
            $0.groups = .mockObjects(.init(
                groups
            ))
            $0.unCompletedTasks = .mockObjects(.init(dataSource.unCompleted))
            $0.completedTasks = .mockObjects(.init(dataSource.completed))
        }
        .environment(\.updateGroup) { group in
            if group.id == .string("createNewGroup") {
                let newGroup = TodoGroup(id: .uuid(UUID()), title: group.title, taskCount: 0)
                await MainActor.run {
                    groups.append(MockGroup(newGroup).eraseToAny())
                }
            }
            guard let index = await groups.firstIndex(where: { $0.id == group.id }) else { return }
            await (groups[index]._object as? MockGroup)?.title = group.title
        }
        .environment(\.deleteGroup) { group in
            await MainActor.run {
                guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
                groups.remove(at: index)
            }
        }
        .environment(\.taskCount, mockCountStream)
        .environment(\.deleteTask) { task in
            await MainActor.run {
                guard let index = dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return }
                dataSource.tasks.remove(at: index)
            }
        }
        .environment(\.updateTask) { task in
            await MainActor.run {
                guard let index = dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return }
                (dataSource.tasks[index]._object as? MockTask)?.update(task)
                id = UUID()
            }
        }
        .environment(\.createNewTask) { task, _ in
            await MainActor.run {
                let newTask: TodoTask = .init(
                    id: .uuid(UUID()),
                    priority: task.priority,
                    createDate: task.createDate,
                    title: task.title,
                    completed: task.completed,
                    myDay: task.myDay
                )
                dataSource.tasks.append(MockTask(newTask).eraseToAny())
            }
        }
        .environment(\.getTaskObject) { task in
            let result: AnyConvertibleValueObservableObject<TodoTask>? = nil
            guard let index = await dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return result }
            return await dataSource.tasks[index]
        }
        .environment(\.updateMemo) { task, memo in
            guard let index = await dataSource.tasks.firstIndex(where: { $0.id == task.id }) else { return }
            await (dataSource.tasks[index]._object as? MockTask)?.memo = memo
        }
    }
}

struct GroupListContainerViewPreview: PreviewProvider {
    static var previews: some View {
        GroupListContainerViewPreviewRoot()
    }
}

import Combine
@Sendable
func mockCountStream(taskSource: TaskSource) async -> AsyncStream<Int> {
    AsyncStream<Int> { c in
        Task {
            let publisher = Timer.publish(every: 2, on: .main, in: .default)
                .autoconnect()
                .map { _ in Int.random(in: 0...20) }
                .prepend(3)

            for await _ in publisher.values where !Task.isCancelled {
                c.yield(Int.random(in: 3...15))
            }
        }
    }
}
#endif
