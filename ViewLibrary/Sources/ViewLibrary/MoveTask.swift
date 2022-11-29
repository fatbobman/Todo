//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/23.
//

import Core
import Foundation
import SwiftUI

public struct MoveTaskToNewGroupView: View {
    @MockableFetchRequest(\.groups) var groups
    @Environment(\.getMovableGroupListRequest) var getMovableGroupListRequest
    let task: TodoTask
    let dismiss: () -> Void
    let movableTaskTargetCellTapped: (WrappedID, WrappedID) -> Void

    public init(
        task: TodoTask,
        dismiss: @escaping () -> Void,
        movableTaskTargetCellTapped: @escaping (WrappedID, WrappedID) -> Void
    ) {
        self.task = task
        self.dismiss = dismiss
        self.movableTaskTargetCellTapped = movableTaskTargetCellTapped
    }

    public var body: some View {
        NavigationStack {
            List(groups) { group in
                let group = group.wrappedValue
                Button {
                    movableTaskTargetCellTapped(task.id, group.id)
                    dismiss()
                }
            label: {
                    Text(group.title)
                }
            }
            .tint(.primary)
            .task {
                guard let request = await getMovableGroupListRequest(task) else { return }
                $groups = request
            }
            .navigationTitle("Select Group")
        }
    }
}

#if DEBUG

struct MoveTaskRootView: View {
    @State var showMoveSheet = false
    var body: some View {
        VStack {
            Button("Show") { showMoveSheet.toggle() }
        }
        .sheet(isPresented: $showMoveSheet) {
            MoveTaskToNewGroupView(task: .sample1, dismiss: {
                showMoveSheet = false
            }, movableTaskTargetCellTapped: { _, _ in })
        }
    }
}

struct MoveTaskViewPreview: PreviewProvider {
    static var previews: some View {
        MoveTaskRootView()
            .transformEnvironment(\.dataSource) {
                $0.groups = .mockObjects(.init([
                    MockGroup(.sample1).eraseToAny(),
                    MockGroup(.sample2).eraseToAny(),
                    MockGroup(.sample3).eraseToAny()
                ]))
            }
    }
}
#endif
