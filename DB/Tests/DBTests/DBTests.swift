import Core
import CoreData
@testable import DB
import XCTest

@MainActor
final class DBTests: XCTestCase {
    func testNewGroup() async throws {
        let container = CoreDataStack.test
        let todoGroup = TodoGroup(id: .integer(0), title: "hello", taskCount: 0)
        await container._createNewGroup(todoGroup)
        let request = NSFetchRequest<C_Group>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let result = try container.viewContext.fetch(request)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, todoGroup.title)
    }

    func testUpdateGroup() async throws {
        let container = CoreDataStack.test
        let todoGroup = TodoGroup(id: .integer(0), title: "hello", taskCount: 0)
        await container._createNewGroup(todoGroup)
        let request = NSFetchRequest<C_Group>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        var group = try container.viewContext.fetch(request).first!.convertToValueType()
        // change
        group.title = "New"
        await container._updateGroup(group)
        let newGroup = try container.viewContext.fetch(request).first!.convertToValueType()
        XCTAssertEqual(group.id, newGroup.id)
        XCTAssertEqual(newGroup.title, "New")
    }

    func testDeleteGroup() async throws {
        let container = CoreDataStack.test
        let todoGroup = TodoGroup(id: .integer(0), title: "hello", taskCount: 0)
        await container._createNewGroup(todoGroup)
        let request = NSFetchRequest<C_Group>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let group = try container.viewContext.fetch(request).first!.convertToValueType()
        await container._deleteGroup(group)
        let count = try container.viewContext.fetch(request).count
        XCTAssertEqual(count, 0)
    }
}
