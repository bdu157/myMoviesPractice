//
//  Movie+Convenience.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 10/12/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData

extension Movie {
    
    //computed property to get the movieRepresenation
    
    //this is for PUT and syncying. Movie coreData itself (SQLlight itself wont encode and be sent the server)
    var movieRepresenation: MovieRepresentation? {
        //requried field which is not optional
        guard let title = self.title else {return nil}
        
        return MovieRepresentation(title: title, identifier: identifier, hasWatched: hasWatched)
    }
    
    convenience init(title: String, hasWatched: Bool = false, identifier: UUID = UUID(), context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.title = title
        self.hasWatched = hasWatched
        self.identifier = identifier
    }
    

    //failable representation because this wont necessarily need to be initialized
    convenience init?(movieRepresenation: MovieRepresentation, backgroundContext: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
    //handle optionals here
    guard let identifier = movieRepresenation.identifier,
        let hasWatched = movieRepresenation.hasWatched else {return nil}
        
        self.init(title: movieRepresenation.title,
                  hasWatched: hasWatched,
                  identifier: identifier,
                  context: backgroundContext)
    }
}

