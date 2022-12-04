//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/26.
//

import Core
import CoreData
@testable import DB
import Foundation
import XCTest

@MainActor
final class AnyConvertibleValueObservableObjectTests: XCTestCase {
    override func tearDown() async throws {
        try await super.tearDown()
        try await Task.sleep(for: .seconds(0.3))
    }
    
    func testToAny() async throws {
        let stack = CoreDataStack.test
        let count = 10000
        await stack.container.performBackgroundTask { context in
            var objects: [NSManagedObject] = []
            for _ in 0..<count {
                let group = C_Group(context: context)
                group.title = UUID().uuidString
                objects.append(group)
            }
            try? context.save()
        }

        let request = C_Group.fetchRequest()
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let result = try stack.viewContext.fetch(request)
        XCTAssertEqual(result.count, count)
        var anyObject = [AnyConvertibleValueObservableObject<TodoGroup>]()
        // average: 0.004
        measure {
            anyObject = result.map { $0.eraseToAny() }
            anyObject.removeAll()
        }
    }

    func testToConvert() async throws {
        let stack = CoreDataStack.test
        let count = 10000
        await stack.container.performBackgroundTask { context in
            var objects: [NSManagedObject] = []
            for _ in 0..<count {
                let group = C_Group(context: context)
                group.title = UUID().uuidString
                objects.append(group)
            }
            try? context.save()
        }

        let request = C_Group.fetchRequest()
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let result = try stack.viewContext.fetch(request)
        XCTAssertEqual(result.count, count)
        var groups = [TodoGroup]()
        // average: 0.015
        measure {
            groups = result.map { $0.convertToValueType()! }
            groups.removeAll()
        }
    }
}
