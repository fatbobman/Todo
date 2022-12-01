//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/23.
//

import Core
import Foundation
import SwiftUI

public struct GroupCell: View {
    @ObservedObject var groupObject: AnyConvertibleValueObservableObject<TodoGroup>
    let deletedGroupButtonTapped: (TodoGroup) -> Void
    let updateGroupButtonTapped: (TodoGroup) -> Void
    let groupCellTapped: (TaskSource) -> Void

    public init(groupObject: AnyConvertibleValueObservableObject<TodoGroup>,
                deletedGroupButtonTapped: @escaping (TodoGroup) -> Void,
                updateGroupButtonTapped: @escaping (TodoGroup) -> Void,
                groupCellTapped: @escaping (TaskSource) -> Void) {
        self.groupObject = groupObject
        self.deletedGroupButtonTapped = deletedGroupButtonTapped
        self.updateGroupButtonTapped = updateGroupButtonTapped
        self.groupCellTapped = groupCellTapped
    }

    public var body: some View {
        if let group = groupObject.wrappedValue {
            Button {
                groupCellTapped(.list(group))
            }
        label: {
                LabeledContent(group.title, value: group.taskCount == 0 ? "" : "\(group.taskCount)")
                    .animation(.default, value: group)
            }
            .tint(.primary)
            .swipeActions(edge: .leading) {
                Button {
                    updateGroupButtonTapped(group)
                } label: {
                    Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    deletedGroupButtonTapped(group)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            }
        }
    }
}

public struct SystemGroupCell: View {
    @Environment(\.taskCount) var taskCount
    let groupClicked: (TaskSource) async -> Void
    let groupType: GroupType
    @State var count = 0

    public init(groupType: GroupType, groupClicked: @escaping (TaskSource) -> Void) {
        self.groupClicked = groupClicked
        self.groupType = groupType
    }

    public var body: some View {
        Button {
            Task {
                await groupClicked(groupType.taskSource)
            }
        }
        label: {
            LabeledContent(groupType.rawValue, value: count == 0 ? "" : "\(count)")
                .animation(.default, value: count)
        }
        .tint(.primary)
        .task {
            for await count in await taskCount(groupType.taskSource) {
                self.count = count
            }
        }
        .moveDisabled(true)
        .deleteDisabled(true)
    }

    public enum GroupType: String {
        case all = "All"
        case myDay = "MyDay"
        case completed = "Completed"

        var taskSource: TaskSource {
            switch self {
            case .all:
                return .all
            case .completed:
                return .completed
            case .myDay:
                return .myDay
            }
        }
    }
}

#if DEBUG
struct GroupCellRootView: View {
    @State var showAlert = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    SystemGroupCell(groupType: .all, groupClicked: { _ in })
                    SystemGroupCell(groupType: .myDay, groupClicked: { _ in })
                    SystemGroupCell(groupType: .completed, groupClicked: { _ in })
                }
                Section("Groups") {
                    GroupCell(
                        groupObject: MockGroup(.sample1).eraseToAny(),
                        deletedGroupButtonTapped: { _ in },
                        updateGroupButtonTapped: { _ in },
                        groupCellTapped: { _ in }
                    )
                    GroupCell(groupObject: MockGroup(.sample2).eraseToAny(),
                              deletedGroupButtonTapped: { _ in },
                              updateGroupButtonTapped: { _ in },
                              groupCellTapped: { _ in })
                    GroupCell(groupObject: MockGroup(.sample3).eraseToAny(),
                              deletedGroupButtonTapped: { _ in },
                              updateGroupButtonTapped: { _ in },
                              groupCellTapped: { _ in })
                }
            }
            .toolbar {
                TodoGroupListToolBar(perform: { showAlert.toggle() })
            }
            // alert 在 preview 中目前仍有问题
            .alert("Group", isPresented: $showAlert) {
                ModifierGroupView(group: .sample1, perform: { _ in })
            }
        }
    }
}

struct GroupCellPreview: PreviewProvider {
    static var previews: some View {
        GroupCellRootView()
    }
}
#endif
