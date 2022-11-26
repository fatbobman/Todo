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
    func testConvert() async throws {
        let stack = CoreDataStack.test
        await stack.container.performBackgroundTask { context in
            var objects: [NSManagedObject] = []
            for _ in 0..<10000 {
                let group = C_Group(context: context)
                group.title = UUID().uuidString
                objects.append(group)
            }
            try? context.save()
        }

        let request = C_Group.fetchRequest()
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let result = try stack.viewContext.fetch(request)
        XCTAssertEqual(result.count, 10000)
        var anyObject = [AnyConvertibleValueObservableObject<TodoGroup>]()
        measure {
            anyObject = result.map { $0.eraseToAny() }
            anyObject.removeAll()
        }
    }
}
