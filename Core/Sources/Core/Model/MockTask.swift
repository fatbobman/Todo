//
//  File.swift
//
//
//  Created by Yang Xu on 2022/11/22.
//

import Foundation

#if DEBUG
public final class MockTask: TestableConvertibleValueObservableObject {
    public var _wrappedValue: TodoTask
    public required init(_ wrappedValue: TodoTask) {
        self._wrappedValue = wrappedValue
    }
}

public final class MockMemo: TestableConvertibleValueObservableObject {
    public var _wrappedValue: TaskMemo
    public required init(_ wrappedValue: TaskMemo) {
        self._wrappedValue = wrappedValue
    }
}

public final class MockGroup: TestableConvertibleValueObservableObject {
    public var _wrappedValue: TodoGroup
    public required init(_ wrappedValue: TodoGroup) {
        self._wrappedValue = wrappedValue
    }
}
#endif
