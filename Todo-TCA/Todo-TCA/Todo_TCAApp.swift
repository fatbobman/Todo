//
//  Todo_TCAApp.swift
//  Todo-TCA
//
//  Created by Yang Xu on 2022/11/28.
//

import ComposableArchitecture
import DB
import Features
import SwiftUI

@main
struct Todo_TCAApp: App {
    let stack = CoreDataStack.shared
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GroupListContainerView(
                    store: .init(
                        initialState: .init(),
                        reducer: GroupListReducer()
                            .dependency(\.createNewGroup, stack.createNewGroup)
                            .dependency(\.updateGroup, stack.updateGroup)
                            .dependency(\.deleteGroup, stack.deleteGroup)
                            .dependency(\.createNewTask, stack.createNewTask)
                            .dependency(\.updateTask, stack.updateTask)
                            .dependency(\.deleteTask, stack.deleteTask)
                            .dependency(\.moveTask, stack.moveTask)
                            .dependency(\.updateMemo, stack.updateMemo)
                    )
                )
            }
            .environment(\.managedObjectContext, stack.viewContext)
            .environment(\.getTodoListRequest, stack.getTodoListRequest)
            .environment(\.getTodoGroupRequest, stack.getTodoGroupRequest)
            .environment(\.getTaskObject, stack.getTaskObject)
            .environment(\.getMovableGroupListRequest, stack.getMovableGroupListRequest)
            .environment(\.taskCount, stack.taskCount)
            .transformEnvironment(\.dataSource) {
                $0.completedTasks = .fetchRequest
                $0.groups = .fetchRequest
                $0.unCompletedTasks = .fetchRequest
            }
        }
    }
}
