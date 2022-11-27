//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/22.
//

import Combine
import CoreData
import Foundation

public protocol BaseValueProtocol: Equatable, Identifiable, Sendable {
    var id: WrappedID { get }
}

public protocol ConvertibleValueObservableObject<Value>: ObservableObject, Equatable, Identifiable where ID == WrappedID {
    associatedtype Value: BaseValueProtocol
    func convertToValueType() -> Value
}

public enum WrappedID: Equatable, Identifiable, Sendable, Hashable {
    case string(String)
    case integer(Int)
    case uuid(UUID)
    case objectID(NSManagedObjectID)

    public var id: Self {
        self
    }

    public var objectID: NSManagedObjectID? {
        guard case .objectID(let objectID) = self else {
            return nil
        }
        return objectID
    }

    public var string: String? {
        guard case .string(let string) = self else {
            return nil
        }
        return string
    }

    public var integer: Int? {
        guard case .integer(let integer) = self else {
            return nil
        }
        return integer
    }

    public var uuid: UUID? {
        guard case .uuid(let uuid) = self else {
            return nil
        }
        return uuid
    }
}

extension WrappedID: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
        case .string(let string):
            return string
        case .integer(let integer):
            return "\(integer)"
        case .uuid(let uuid):
            return uuid.uuidString
        case .objectID(let objectID):
            return objectID.description
        }
    }

    public var debugDescription: String {
        description
    }
}

extension NSManagedObjectID: @unchecked Sendable {}

@dynamicMemberLookup
public protocol TestableConvertibleValueObservableObject<WrappedValue>: ConvertibleValueObservableObject {
    associatedtype WrappedValue where WrappedValue: BaseValueProtocol
    var _wrappedValue: WrappedValue { get set }
    init(_ wrappedValue: WrappedValue)
    subscript<Value>(dynamicMember keyPath: WritableKeyPath<WrappedValue, Value>) -> Value { get set }
}

public extension TestableConvertibleValueObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    subscript<Value>(dynamicMember keyPath: WritableKeyPath<WrappedValue, Value>) -> Value {
        get {
            _wrappedValue[keyPath: keyPath]
        }
        set {
            self.objectWillChange.send()
            _wrappedValue[keyPath: keyPath] = newValue
        }
    }

    func update(_ wrappedValue: WrappedValue) {
        self.objectWillChange.send()
        _wrappedValue = wrappedValue
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._wrappedValue == rhs._wrappedValue
    }

    func convertToValueType() -> WrappedValue {
        _wrappedValue
    }

    var id: WrappedValue.ID {
        _wrappedValue.id
    }
}

public protocol ObjectFetcherProtocol<ConvertValue> {
    associatedtype ConvertValue: BaseValueProtocol
    var stream: AsyncPublisher<AnyPublisher<[any ConvertibleValueObservableObject<ConvertValue>], Never>> { get }
}

public extension Equatable where Self: ConvertibleValueObservableObject {
    func isEquatable(other: any ConvertibleValueObservableObject) -> Bool {
        guard let other = other as? Self else { return false }
        return self.id == other.id
    }
}

public class AnyConvertibleValueObservableObject<Value>: ObservableObject, Identifiable where Value: BaseValueProtocol {
    public var _object: any ConvertibleValueObservableObject<Value>
    public var id: WrappedID {
        _object.id
    }

    public var wrappedValue: Value {
        _object.convertToValueType()
    }

    init(object: some ConvertibleValueObservableObject<Value>) {
        self._object = object
    }

    public var objectWillChange: ObjectWillChangePublisher {
        _object.objectWillChange as! ObservableObjectPublisher
    }
}

extension AnyConvertibleValueObservableObject : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension AnyConvertibleValueObservableObject: Equatable {
    public static func == (lhs: AnyConvertibleValueObservableObject<Value>, rhs: AnyConvertibleValueObservableObject<Value>) -> Bool {
        lhs._object.isEquatable(other: rhs._object)
    }
}

public extension ConvertibleValueObservableObject {
    func eraseToAny() -> AnyConvertibleValueObservableObject<Value> {
        AnyConvertibleValueObservableObject(object: self)
    }
}
