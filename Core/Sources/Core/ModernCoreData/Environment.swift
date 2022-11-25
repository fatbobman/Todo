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

public struct ObjectsDataSource: Equatable {
    public var unCompletedTasks: FetchDataSource<TodoTask>
    public var completedTasks: FetchDataSource<TodoTask>
    public var groups: FetchDataSource<TodoGroup>
}

public extension ObjectsDataSource {
    static let `default` = ObjectsDataSource(
        unCompletedTasks: .mockObjects(.init([MockTask(.sample1).eraseToAny()])),
        completedTasks: .mockObjects(.init([MockTask(.sample3).eraseToAny()])),
        groups: .mockObjects(.init([MockGroup(.sample1).eraseToAny()]))
    )
}

public struct ObjectsDataSourceKey: EnvironmentKey {
    public static var defaultValue: ObjectsDataSource = .default
}

public extension EnvironmentValues {
    var dataSource: ObjectsDataSource {
        get { self[ObjectsDataSourceKey.self] }
        set { self[ObjectsDataSourceKey.self] = newValue }
    }
}
