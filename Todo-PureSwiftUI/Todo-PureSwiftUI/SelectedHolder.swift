//
//  PathHolder.swift
//  Todo-PureSwiftUI
//
//  Created by Yang Xu on 2022/11/25.
//

import Combine
import Core
import Foundation

final class SelectedTaskHolder: ObservableObject {
    @Published var selectedTask: TodoTask?
    init(selectedTask: TodoTask? = nil) {
        self.selectedTask = selectedTask
    }
}

final class SelectedSourceHolder: ObservableObject {
    @Published var selectedTaskSource: TaskSource?
    init(selectedTaskSource: TaskSource? = nil) {
        self.selectedTaskSource = selectedTaskSource
    }
}
