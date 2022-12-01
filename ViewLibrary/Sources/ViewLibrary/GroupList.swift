//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/23.
//

import Core
import Foundation
import SwiftUI

public struct GroupListView: View {
    @MockableFetchRequest(\ObjectsDataSource.groups) var groups
    @Environment(\.getTodoGroupRequest) var getTodoGroupRequest
    let deletedGroupButtonTapped: (TodoGroup) -> Void
    let updateGroupButtonTapped: (TodoGroup) -> Void
    let groupCellTapped: (TaskSource) -> Void
    let createNewGroupButtonTapped: () -> Void

    public init(deletedGroupButtonTapped: @escaping (TodoGroup) -> Void,
                updateGroupButtonTapped: @escaping (TodoGroup) -> Void,
                groupCellTapped: @escaping (TaskSource) -> Void,
                createNewGroupButtonTapped: @escaping () -> Void) {
        self.deletedGroupButtonTapped = deletedGroupButtonTapped
        self.updateGroupButtonTapped = updateGroupButtonTapped
        self.groupCellTapped = groupCellTapped
        self.createNewGroupButtonTapped = createNewGroupButtonTapped
    }

    public var body: some View {
        List {
            Section {
                SystemGroupCell(groupType: .all, groupClicked: groupCellTapped)
                SystemGroupCell(groupType: .myDay, groupClicked: groupCellTapped)
                SystemGroupCell(groupType: .completed, groupClicked: groupCellTapped)
            }
            Section("Groups") {
                ForEach(groups) { group in
                    GroupCell(
                        groupObject: group,
                        deletedGroupButtonTapped: deletedGroupButtonTapped,
                        updateGroupButtonTapped: updateGroupButtonTapped,
                        groupCellTapped: groupCellTapped
                    )
                }
            }
        }
        .toolbar {
            TodoGroupListToolBar(perform: { createNewGroupButtonTapped() })
        }
        .task {
            guard let request = await getTodoGroupRequest() else { return }
            $groups = request
        }
        .navigationTitle("Todo Groups")
    }
}

#if DEBUG
struct GroupListViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GroupListView(
                deletedGroupButtonTapped: { _ in },
                updateGroupButtonTapped: { _ in },
                groupCellTapped: { _ in },
                createNewGroupButtonTapped: {}
            )
        }
    }
}
#endif
