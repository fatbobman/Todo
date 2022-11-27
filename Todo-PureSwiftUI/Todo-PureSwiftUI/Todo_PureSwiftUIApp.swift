//
//  Todo_PureSwiftUIApp.swift
//  Todo-PureSwiftUI
//
//  Created by Yang Xu on 2022/11/25.
//

import Core
import SwiftUI
import ViewLibrary
import DB

@main
struct Todo_PureSwiftUIApp: App {
    @StateObject var selectionHolder = SelectionHolder()
    let stack = CoreDataStack.shared
    var body: some Scene {
        WindowGroup {
            GroupListContainerView()
                .environmentObject(selectionHolder) // keep
                .environment(\.managedObjectContext, stack.viewContext)
                .environment(\.createNewGroup, stack.createNewGroup)
                .environment(\.updateGroup, stack.updateGroup)
                .environment(\.deleteGroup, stack.deleteGroup)
                .environment(\.createNewTask, stack.createNewTask)
                .environment(\.updateTask, stack.updateTask)
                .environment(\.deleteTask, stack.deleteTask)
                .environment(\.moveTask, stack.moveTask)
//                .environment(\.updateMemo, stack.updateMemo)
                .environment(\.getTodoListRequest, stack.getTodoListRequest)
                .environment(\.getTodoGroupRequest, stack.getTodoGroupRequest)
                .environment(\.getTaskObject, stack.getTaskObject)
                .environment(\.getMovableGroupListRequest, stack.getMovableGroupListRequest)
                .environment(\.taskCount, stack.taskCount)
                .transformEnvironment(\.dataSource){
                    $0.completedTasks = .fetchRequest
                    $0.groups = .fetchRequest
                    $0.unCompletedTasks = .fetchRequest
                }
        }
    }
}
