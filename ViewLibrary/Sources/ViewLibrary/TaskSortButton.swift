//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/24.
//

import Core
import Foundation
import SwiftUI

public struct TaskSortButton: View {
    @Binding var taskSortType: TaskSortType
    public init(taskSortType: Binding<TaskSortType>) {
        self._taskSortType = taskSortType
    }

    public var body: some View {
        Menu {
            ForEach(TaskSortType.allCases) { type in
                Button {
                    taskSortType = type
                } label: {
                    LabeledContent(type.rawValue) {
                        if type == taskSortType {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}
