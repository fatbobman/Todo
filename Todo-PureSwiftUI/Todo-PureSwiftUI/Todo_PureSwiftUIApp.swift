//
//  Todo_PureSwiftUIApp.swift
//  Todo-PureSwiftUI
//
//  Created by Yang Xu on 2022/11/25.
//

import Core
import SwiftUI
import ViewLibrary

@main
struct Todo_PureSwiftUIApp: App {
    @State var groups: [AnyConvertibleValueObservableObject<TodoGroup>] = [
        MockGroup(.sample1).eraseToAny(),
        MockGroup(.sample2).eraseToAny(),
        MockGroup(.sample3).eraseToAny()
    ]
    @StateObject var dataSource = ListContainerDataSource()
    @State var id = UUID()
    @StateObject var selectionHolder = SelectionHolder()

    var body: some Scene {
        WindowGroup {
            GroupListContainerView()
                .environmentObject(selectionHolder) // keep
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
                .environment(\.taskCount, mockCountPublisher)
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
}
