//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/23.
//

import Core
import Foundation
import SwiftUI

// create or edit Todo Group
public struct ModifierGroupView: View {
    let group: TodoGroup?
    @State var groupName: String
    let perform: (TodoGroup) -> Void

    public init(group: TodoGroup?,
                perform: @escaping (TodoGroup) -> Void) {
        self.group = group
        if let group {
            _groupName = State(wrappedValue: group.title)
        } else {
            _groupName = State(wrappedValue: "")
        }
        self.perform = perform
    }

    public var body: some View {
        TextField("Group Name", text: $groupName)
        Button(group != nil ? "Confirm" : "Create", action: {
            if var group {
                group.title = String(groupName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Configuration.groupTitleMaxLength))
                perform(group)
            } else {
                let group = TodoGroup(
                    id: .string("createNewGroup"),
                    title: String(groupName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Configuration.groupTitleMaxLength)),
                    taskCount: 0
                )
                perform(group)
            }
            empty()
        })
        Button("Cancel", role: .cancel, action: {
            empty()
        })
    }

    func empty() {
        groupName = ""
    }
}

public struct TodoGroupListToolBar: ToolbarContent {
    let perform: () -> Void
    public var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                perform()
            } label: {
                Image(systemName: "square.and.pencil")
            }
        }
    }
}
