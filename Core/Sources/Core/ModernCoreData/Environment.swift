//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/22.
//

import Foundation
import SwiftUI

public struct EquatableObjects<Value>: Equatable where Value: BaseValueProtocol {
    public var values: [AnyConvertibleValueObservableObject<Value>]

    public static func== (lhs: Self, rhs: Self) -> Bool {
        guard lhs.values.count == rhs.values.count else { return false }
        for index in lhs.values.indices {
            if !lhs.values[index]._object.isEquatable(other: rhs.values[index]._object) { return false }
        }
        return true
    }

    public init(_ values: [AnyConvertibleValueObservableObject<Value>]) {
        self.values = values
    }
}

public enum FetchDataSource<Value>: Equatable where Value: BaseValueProtocol {
    case fetchRequest
    case mockObjects(EquatableObjects<Value>)
}

public struct ObjectsDataSource: ObjectsDataSourceProtocol {
    public var unCompletedTasks: FetchDataSource<TodoTask>
    public var completedTasks: FetchDataSource<TodoTask>
    public var groups: FetchDataSource<TodoGroup>

    public init(
        unCompletedTasks: FetchDataSource<TodoTask>,
        completedTasks: FetchDataSource<TodoTask>,
        groups: FetchDataSource<TodoGroup>
    ) {
        self.unCompletedTasks = unCompletedTasks
        self.completedTasks = completedTasks
        self.groups = groups
    }
}

public extension ObjectsDataSource {
    static let `default` = ObjectsDataSource(
        unCompletedTasks: .mockObjects(.init([MockTask(.sample1).eraseToAny()])),
        completedTasks: .mockObjects(.init([MockTask(.sample3).eraseToAny()])),
        groups: .mockObjects(.init([MockGroup(.sample1).eraseToAny()]))
    )

    static let live = ObjectsDataSource(unCompletedTasks: .fetchRequest, completedTasks: .fetchRequest, groups: .fetchRequest)
}

public struct ObjectsDataSourceKey: EnvironmentKey {
    public static var defaultValue: any ObjectsDataSourceProtocol = ObjectsDataSource.default
}

public extension EnvironmentValues {
    var dataSource: any ObjectsDataSourceProtocol {
        get { self[ObjectsDataSourceKey.self] }
        set { self[ObjectsDataSourceKey.self] = newValue }
    }
}

public protocol ObjectsDataSourceProtocol: Equatable {}
