//
//  CoreDataStack.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 10/12/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    // stored property
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Movies")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    //computed property
    var mainContext: NSManagedObjectContext {
        return self.container.viewContext
    }
}
