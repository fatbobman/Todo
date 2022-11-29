//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/29.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import ViewLibrary

public struct GroupListContainerView: View {
    let store: StoreOf<GroupListReducer>

    public init(store: StoreOf<GroupListReducer>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            GroupListView(
                deletedGroupButtonTapped: { viewStore.send(.deletedGroupButtonTapped($0)) },
                updateGroupButtonTapped: { viewStore.send(.updateGroupButtonTapped($0)) },
                groupCellTapped: { viewStore.send(.groupCellTapped($0)) },
                createNewGroupButtonTapped: { viewStore.send(.createNewGroupButtonTapped) }
            )
            .navigationDestination(store.scope(state: \.taskList, action: GroupListReducer.Action.taskListAction), dismissAction: .dismiss) { store in
                TaskListContainerView(store: store)
            }
            .alert(
                viewStore.groupEditMode == .new ? "New Group" : "Edit Group",
                isPresented: Binding(
                    get: { viewStore.groupEditMode != nil },
                    set: { if !$0 { viewStore.send(.groupEditorDismiss) }}
                )
            ) {
                if case .edit(let group) = viewStore.groupEditMode {
                    ModifierGroupView(
                        group: group,
                        perform: { viewStore.send(.updateGroup($0)) }
                    )
                } else {
                    ModifierGroupView(
                        group: nil,
                        perform: { viewStore.send(.createGroup($0)) }
                    )
                }
            }
            .alert(store.scope(state: \.deleteConfirmAlert), dismiss: .deleteConfirmAlertDismiss)
            .navigationDestination(store.scope(state: \.taskList, action: GroupListReducer.Action.taskListAction), dismissAction: .dismiss) { store in
                TaskListContainerView(store: store)
            }
        }
    }
}

#if DEBUG
struct GroupListContainerViewPreviewRoot: View {
    var body: some View {
        GroupListContainerView(
            store: .init(
                initialState: .init(),
                reducer: GroupListReducer()
            )
        )
    }
}

struct GroupListContainerViewPreview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GroupListContainerViewPreviewRoot()
        }
    }
}
#endif
