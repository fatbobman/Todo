//
//  File.swift
//  
//
//  Created by Yang Xu on 2022/11/26.
//

import Foundation
import CoreData

final class CoreDataStack {
    lazy var container:NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        return container
    }()

    private let modelName:String

    init(_ modelName:String = "TodoModel"){
        self.modelName = modelName
    }
}
