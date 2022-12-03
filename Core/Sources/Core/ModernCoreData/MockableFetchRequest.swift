//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/22.
//

import Combine
import CoreData
import Foundation
import SwiftUI

@propertyWrapper
public struct MockableFetchRequest<Root, Value>: DynamicProperty where Value: BaseValueProtocol, Root: ObjectsDataSourceProtocol {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dataSource) var dataSource

    @State var values: [AnyConvertibleValueObservableObject<Value>] = []
    public var wrappedValue: [AnyConvertibleValueObservableObject<Value>] {
        values
    }

    let objectKeyPath: KeyPath<Root, FetchDataSource<Value>>
    let animation: Animation?
    let fetchRequest: NSFetchRequest<NSManagedObject>?
    @State var updateWrappedValue = MutableHolder<([AnyConvertibleValueObservableObject<Value>]) -> Void>({ _ in })
    @State var firstUpdate = MutableHolder<Bool>(true)
    @State var fetcher = MutableHolder<ConvertibleValueObservableObjectFetcher<Value>?>(nil)
    @State var cancellable = MutableHolder<AnyCancellable?>(nil)
    @State var sender = PassthroughSubject<[AnyConvertibleValueObservableObject<Value>], Never>()

    public init(
        _ objectKeyPath: KeyPath<Root, FetchDataSource<Value>>,
        fetchRequest: NSFetchRequest<NSManagedObject>? = nil,
        animation: Animation? = .default
    ) {
        self.objectKeyPath = objectKeyPath
        self.animation = animation
        self.fetchRequest = fetchRequest
    }

    public var publisher: AnyPublisher<Void, Never> {
        sender
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    public func update() {
        // set updateWrappedValue
        let values = _values
        let firstUpdate = firstUpdate
        let animation = animation
        updateWrappedValue.value = { data in
            var animation = animation
            if firstUpdate.value {
                animation = nil
                firstUpdate.value = false
            }
            withAnimation(animation) {
                values.wrappedValue = data
            }
        }

        if cancellable.value == nil {
            cancellable.value = sender
                .delay(for: .nanoseconds(1), scheduler: RunLoop.main)
                .removeDuplicates {
                    EquatableObjects($0) == EquatableObjects($1)
                }
                .receive(on: DispatchQueue.main)
                .sink {
                    updateWrappedValue.value($0)
                }
        }

        // fetch Request
        if let dataSource = dataSource as? Root, case .fetchRequest = dataSource[keyPath: objectKeyPath], fetcher.value == nil {
            fetcher.value = .init(sender: sender)
            if let fetchRequest {
                updateFetchRequest(fetchRequest)
            }
        }

        // mock objects
        if let dataSource = dataSource as? Root, case .mockObjects(let objects) = dataSource[keyPath: objectKeyPath], objects != EquatableObjects(_values.wrappedValue) {
            sender.send(objects.values)
        }
    }

    func updateFetchRequest(_ request: NSFetchRequest<NSManagedObject>) {
        if let dataSource = dataSource as? Root, case .fetchRequest = dataSource[keyPath: objectKeyPath] {
            fetcher.value?.updateRequest(context: viewContext, request: request)
        }
    }

    public var projectedValue: NSFetchRequest<NSManagedObject>? {
        get { fetcher.value?.fetcher?.fetchRequest ?? fetchRequest }
        nonmutating set {
            if let request = newValue {
                updateFetchRequest(request)
            }
        }
    }
}

extension MockableFetchRequest {
    final class MutableHolder<T> {
        var value: T
        @inlinable
        init(_ value: T) {
            self.value = value
        }
    }
}

final class ConvertibleValueObservableObjectFetcher<Value>: NSObject, NSFetchedResultsControllerDelegate where Value: BaseValueProtocol {
    var fetcher: NSFetchedResultsController<NSManagedObject>?
    let sender: PassthroughSubject<[AnyConvertibleValueObservableObject<Value>], Never>

    func updateRequest(context: NSManagedObjectContext, request: NSFetchRequest<NSManagedObject>) {
        precondition(context.concurrencyType == .mainQueueConcurrencyType, "只支持类型为 main Queue 的托管对象上下文")
        fetcher = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetcher?.delegate = self
        do {
            try fetcher?.performFetch()
        } catch {
            fatalError("Perform request error: \(error.localizedDescription)")
        }
        publishValue(fetcher?.fetchedObjects)
    }

    init(sender: PassthroughSubject<[AnyConvertibleValueObservableObject<Value>], Never>) {
        self.sender = sender
    }

    func publishValue(_ values: [NSFetchRequestResult]?) {
        guard let values else { return }
        let results = values.compactMap {
            ($0 as? any ConvertibleValueObservableObject<Value>)?.eraseToAny()
        }
        sender.send(results)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        publishValue(controller.fetchedObjects)
    }
}
