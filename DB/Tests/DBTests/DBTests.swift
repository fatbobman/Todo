import Core
import CoreData
@testable import DB
import XCTest

@MainActor
final class DBTests: XCTestCase {
    func testNewGroup() async throws {
        let stack = CoreDataStack.test
        let todoGroup = TodoGroup(id: .integer(0), title: "hello", taskCount: 0)
        await stack._createNewGroup(todoGroup)
        let request = NSFetchRequest<C_Group>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let result = try stack.viewContext.fetch(request)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, todoGroup.title)
    }

    func testUpdateGroup() async throws {
        let stack = CoreDataStack.test
        let todoGroup = TodoGroup(id: .integer(0), title: "hello", taskCount: 0)
        await stack._createNewGroup(todoGroup)
        let request = NSFetchRequest<C_Group>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        var group = try stack.viewContext.fetch(request).first!.convertToValueType()
        // change
        group.title = "New"
        await stack._updateGroup(group)
        let newGroup = try stack.viewContext.fetch(request).first!.convertToValueType()
        XCTAssertEqual(group.id, newGroup.id)
        XCTAssertEqual(newGroup.title, "New")
    }

    func testDeleteGroup() async throws {
        let stack = CoreDataStack.test
        let todoGroup = TodoGroup(id: .integer(0), title: "hello", taskCount: 0)
        await stack._createNewGroup(todoGroup)
        let request = NSFetchRequest<C_Group>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let group = try stack.viewContext.fetch(request).first!.convertToValueType()
        await stack._deleteGroup(group)
        let count = try stack.viewContext.fetch(request).count
        XCTAssertEqual(count, 0)
    }

    func testCreateNewTask() async throws {
        let stack = CoreDataStack.test
        let todoGroup = TodoGroup.sample1
        await stack._createNewGroup(todoGroup)
        let request = NSFetchRequest<C_Group>(entityName: "C_Group")
        request.sortDescriptors = [.init(key: "title", ascending: true)]
        let group = try stack.viewContext.fetch(request).first!

        let task = TodoTask.sample1
        await stack._createNewTask(task, .list(group.convertToValueType()))
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let result = try stack.viewContext.fetch(taskRequest)
        XCTAssertEqual(result.count, 1)
        let todoTask = result.first!

        XCTAssertEqual(todoTask.group?.id, group.id)
    }

    func testCreateNewTaskWithoutGroup() async throws {
        let stack = CoreDataStack.test

        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let result = try stack.viewContext.fetch(taskRequest)
        XCTAssertEqual(result.count, 1)
        let todoTask = result.first!

        XCTAssertEqual(todoTask.title, task.title)
    }

    func testUpdateTask() async throws {
        let stack = CoreDataStack.test
        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        var todoTask = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        todoTask.title = "New"
        await stack._updateTask(todoTask)
        let newTask = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        XCTAssertEqual(newTask.id, todoTask.id)
        XCTAssertEqual(newTask.title, "New")
    }

    func testDeleteTask() async throws {
        let stack = CoreDataStack.test
        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let todoTask = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        await stack._deleteTask(todoTask)
        XCTAssertEqual(0, try! stack.viewContext.fetch(taskRequest).count)
    }

    func testMoveTask() async throws {
        let stack = CoreDataStack.test
        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let todoTask = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        let group = TodoGroup.sample1
        await stack._createNewGroup(group)
        let groupRequest = C_Group.fetchRequest()
        groupRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let todoGroupObject = try stack.viewContext.fetch(groupRequest).first!
        let todoGroup = todoGroupObject.convertToValueType()
        await stack._moveTask(todoTask.id, todoGroup.id)
        let newTask = try stack.viewContext.fetch(taskRequest).first!
        XCTAssertEqual(newTask.group?.id, todoGroup.id)
    }

    func testGetTask() async throws {
        let stack = CoreDataStack.test
        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let taskValue = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        let taskObject = await stack._getTaskObject(taskValue)
        XCTAssertEqual(taskObject?.id, taskValue.id)
    }

    func testUpdateMemoNew() async throws {
        let stack = CoreDataStack.test
        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let taskValue = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        let memo = TaskMemo.sample1
        await stack._updateMemo(taskValue, memo)
        let taskObject = try stack.viewContext.fetch(taskRequest).first!
        XCTAssertNotNil(taskObject.memo)
        XCTAssertEqual(taskObject.memo?.content, memo.content)
    }

    func testUpdateMemoDelete() async throws {
        let stack = CoreDataStack.test
        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let taskValue = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        let memo = TaskMemo.sample1
        await stack._updateMemo(taskValue, memo)
        let taskObject = try stack.viewContext.fetch(taskRequest).first!
        XCTAssertNotNil(taskObject.memo)
        XCTAssertEqual(taskObject.memo?.content, memo.content)
        await stack._updateMemo(taskValue, nil)
        let taskObject1 = try stack.viewContext.fetch(taskRequest).first!
        XCTAssertNil(taskObject1.memo)
    }

    func testUpdateMemoReplace() async throws {
        let stack = CoreDataStack.test
        let task = TodoTask.sample1
        await stack._createNewTask(task, .all)
        let taskRequest = NSFetchRequest<C_Task>(entityName: "C_Task")
        taskRequest.sortDescriptors = [.init(key: "title", ascending: true)]
        let taskValue = try stack.viewContext.fetch(taskRequest).first!.convertToValueType()
        let memo = TaskMemo.sample1
        await stack._updateMemo(taskValue, memo)
        let taskObject = try stack.viewContext.fetch(taskRequest).first!
        XCTAssertNotNil(taskObject.memo)
        XCTAssertEqual(taskObject.memo?.content, memo.content)
        let memoID = taskObject.memo!.id
        let memo2 = TaskMemo.sample2
        await stack._updateMemo(taskValue, memo2)
        let taskObject1 = try stack.viewContext.fetch(taskRequest).first!
        XCTAssertEqual(taskObject1, taskObject)
        XCTAssertNotEqual(taskObject1.memo?.id, memoID)
        XCTAssertEqual(taskObject1.memo?.content, TaskMemo.sample2.content)
    }

    func testGetGroupRequest() async throws {
        let stack = CoreDataStack.test
        await stack._createNewGroup(.sample1)
        let groupFetch = C_Group.fetchRequest()
        groupFetch.sortDescriptors = [.init(key: "title", ascending: true)]
        let group = try stack.viewContext.fetch(groupFetch).first!
        let groupValue = group.convertToValueType()
        let task1 = TodoTask.sample1 // completed = false Date(timeIntervalSince1970: 0)
        let task2 = TodoTask.sample2 // completed = false Date(timeIntervalSince1970: 1)
        let task3 = TodoTask.sample3 // completed = true Date(timeIntervalSince1970: 2)
        await stack._createNewTask(task1, .list(groupValue))
        await stack._createNewTask(task2, .list(groupValue))
        await stack._createNewTask(task3, .list(groupValue))
        let requests = await stack._getTodoListRequest(.list(groupValue), .createDate)
        let completedTasks = try! stack.viewContext.fetch(requests.completed!)
        let unCompletedTasks = try! stack.viewContext.fetch(requests.unCompleted!)
        XCTAssertEqual(completedTasks.count, 1)
        XCTAssertEqual(unCompletedTasks.count, 2)
        XCTAssertEqual((completedTasks.first! as! C_Task).title, task3.title)
        XCTAssertEqual((unCompletedTasks.first! as! C_Task).title, task2.title)
        XCTAssertEqual((unCompletedTasks.last! as! C_Task).title, task1.title)
    }

    func testGetGroupListRequest() async throws {
        let stack = CoreDataStack.test
        await stack._createNewGroup(.sample1) // title Group1
        await stack._createNewGroup(.sample2) // title Group2
        let request = await stack._getTodoGroupRequest()
        let groups = try! stack.viewContext.fetch(request!)
        XCTAssertEqual((groups.first! as! C_Group).title, TodoGroup.sample1.title)
        XCTAssertEqual((groups.last! as! C_Group).title, TodoGroup.sample2.title)
    }

    func testGetMovableGroupListRequest() async throws {
        let stack = CoreDataStack.test
        await stack._createNewGroup(.sample1) // title Group1
        await stack._createNewGroup(.sample2) // title Group2
        let group1Request = NSFetchRequest<C_Group>(entityName: "C_Group")
        group1Request.predicate = .init(format: "title = %@", TodoGroup.sample1.title)
        group1Request.sortDescriptors = [.init(key: "title", ascending: true)]
        let groups = try! stack.viewContext.fetch(group1Request)
        XCTAssertEqual(groups.count, 1)
        let group1Object = groups.first!
        XCTAssertEqual(group1Object.title, TodoGroup.sample1.title)
        let group1 = group1Object.convertToValueType()
        await stack._createNewTask(.sample1, .list(group1))
        let requestForTask = C_Task.fetchRequest()
        requestForTask.sortDescriptors = [.init(key: "title", ascending: true)]
        let tasks = try! stack.viewContext.fetch(requestForTask)
        XCTAssertEqual(tasks.count, 1)
        let movableRequestForTaskSample1 = await stack._getMovableGroupListRequest(tasks.first!.convertToValueType())
        let movableGroups = try! stack.viewContext.fetch(movableRequestForTaskSample1!)
        XCTAssertEqual(movableGroups.count, 1)
        XCTAssertEqual((movableGroups.first! as! C_Group).title, TodoGroup.sample2.title)
    }

    func testTaskCount() async throws {
        let stack = CoreDataStack.test
        let stream = await stack._taskCount(.all) // .myDay == 2 .completed = 1

        let total = Total()
        let task = Task.detached {
            for await count in stream {
                await total.update(i: count)
            }
        }

        await stack._createNewTask(.sample1, .all)
        await stack._createNewTask(.sample2, .all)
        await stack._createNewTask(.sample3, .all)

        try? await Task.sleep(for: .seconds(0.1))
        task.cancel()
        let count = await total.count
        XCTAssertEqual(count, 3)

        actor Total {
            var count = 0
            func update(i: Int) {
                count = i
            }
        }
    }
}
