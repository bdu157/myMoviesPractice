//
//  MovieController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class MovieController {
    
    // MARK: - Properties
    
    var searchedMovies: [MovieRepresentation] = []
    
    private let apiKey = "4cc920dab8b729a619647ccc4d191d5e"
    private let baseURL = URL(string: "https://api.themoviedb.org/3/search/movie")!
    
    
    init() {
        self.fetchMyMoviesfromtheServer()
    }
    
    
    
    //MARK: Networking for movies search
    func searchForMovie(with searchTerm: String, completion: @escaping (Error?) -> Void) {
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        
        let queryParameters = ["query": searchTerm,
                               "api_key": apiKey]
        
        components?.queryItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        
        guard let requestURL = components?.url else {
            completion(NSError())
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error searching for movie with search term \(searchTerm): \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(NSError())
                return
            }
            
            do {
                let movieRepresentations = try JSONDecoder().decode(MovieRepresentations.self, from: data).results
                self.searchedMovies = movieRepresentations
                completion(nil)
            } catch {
                NSLog("Error decoding JSON data: \(error)")
                completion(error)
            }
            }.resume()
    }
    
    //MARK: Networking - with the server (firebase)
    var baseURL2 = URL(string: "https://task-coredata.firebaseio.com/")!
    
    //GET and private metohds - Read (fetchfromPersistentStore) and Update (datas being fetched from PersistentStore and movieRepresentations being fetched from the server)
    func fetchMyMoviesfromtheServer(completion:@escaping (Error)->Void = {_ in}) {
        let requestURL = baseURL2.appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                NSLog("There is an error fetching mymovies: \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("there is an error getting the data")
                completion(NSError())
                return
            }
            
            let jsonDecoder = JSONDecoder()
            
            do {
                let myMovieRepresentationDictionary = try jsonDecoder.decode([String: MovieRepresentation].self, from: data)
                let myMovieRepresentations = myMovieRepresentationDictionary.map {$0.value}
            
                //add updateMyMovies - fetchdatasfromPersistentStore -> compare it with myMovieRepresentation (datas from the server) and update coreData to reflect what is in the server -> create new movies if they do not exist in persistentStore

                try self.updateMyMovies(with: myMovieRepresentations)
                
            } catch {
                NSLog("Error decoding entry representation: \(error)")
                completion(error)
                return
            }
        }.resume()
    }
    
    //private methods for updateMyMovies <- update (no fetchfrompersistentstore since we do that within updateMyMovies with dictionary being created based on movieRepresentation (from firebase))
    private func updateMyMovies(with representation: [MovieRepresentation]) throws {
        let movieWithID = representation.filter {$0.identifier != ""}
        let identifierToFetch = movieWithID.compactMap{UUID(uuidString: $0.identifier!)}
        
        let representationByID = Dictionary(uniqueKeysWithValues: zip(identifierToFetch, movieWithID))
        
        var movieToCreate = representationByID
        
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifierToFetch)
        
        let backgroundcontext = CoreDataStack.shared.container.newBackgroundContext()
        
        backgroundcontext.perform {
            do {
                let existingMovies = try backgroundcontext.fetch(fetchRequest)
                
                for movie in existingMovies {
                    guard let id = movie.identifier,
                        let representation = representationByID[id] else {continue}
                    self.update(for: movie, with: representation)
                    movieToCreate.removeValue(forKey: id)
                }
                
                for representation  in movieToCreate.values {
                    let _ = Movie(movieRepresenation: representation, backgroundContext: backgroundcontext)
                }
    
            } catch {
                NSLog("Error fetching movies for UUIDs: \(error)")
            }
            
            do {
                try self.saveToPersistentStoreBackgroundContext(bgcontext: backgroundcontext)
            } catch {
                NSLog("there is an error with saving persistentStore")
            }
        }
    }
    
    //updateMovies between datas from firebase and datas from persistentStore
    private func update(for movie: Movie, with representation: MovieRepresentation) {
        movie.hasWatched = representation.hasWatched!
        movie.title = representation.title
    }
    
    
    //PUT
    func put(for movie: Movie, completion:@escaping (Error?) -> Void = { _ in}) {
        guard let identifier = movie.identifier?.uuidString else {return}
        
        let requestURL = baseURL2.appendingPathComponent(identifier).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        
        request.httpMethod = "PUT"
        
        let jsonEncoder = JSONEncoder()
        
        do {
            guard let representation = movie.movieRepresenation else {
                completion(NSError())
                return
            }
            request.httpBody = try jsonEncoder.encode(representation)
        } catch {
            NSLog("error encoding movie: \(movie): \(error)")
            completion(error)
            return
        }
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                NSLog("there is an error in PUTing movie to server:\(error)")
                completion(error)
                return
            }
            completion(nil)
            }.resume()
    }
    
    
    //DELETE
    func deleteMovieFromtheServer(for movie: Movie, completion:@escaping (Error?) -> Void = {_ in}) {
        guard let identifier = movie.identifier?.uuidString else {return}
        
        let requestURL = baseURL2.appendingPathComponent(identifier).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                NSLog("there is an error in deleting :\(movie) - \(error)")
                completion(error)
                return
            }
            completion(nil)
            }.resume()
    }
    
    
    //MARK: CRUD - create, read, update, delete
    
    //Create
    //create(add) movie to persistentStore from searchedMovies
    func addMovie(for movieRep: MovieRepresentation) {
        let movie = Movie(title: movieRep.title)
        self.put(for: movie)
        self.saveToPersistentStore()
    }
    
    //Update
    func toggleSeenButton(for object: Movie) {
        object.hasWatched = !object.hasWatched
        self.put(for: object)
        self.saveToPersistentStore()
    }
    
    //Delete
    func deleteMovie(for object: Movie) {
        self.deleteMovieFromtheServer(for: object)
        let moc = CoreDataStack.shared.mainContext
        moc.delete(object)
        
        self.saveToPersistentStore()
    }

    //
    
    //MAKR: saveToPersistentStore - mainContext and backgroundContext
    //save persistentStore - mainContext
    func saveToPersistentStore() {
        do {
            let moc = CoreDataStack.shared.mainContext
            try moc.save()
        } catch {
            NSLog("Error saving managed object context:\(error)")
        }
    }
    //save persistentStore - backgroundContext
    func saveToPersistentStoreBackgroundContext(bgcontext: NSManagedObjectContext = CoreDataStack.shared.mainContext) throws {
        var error: Error?
        bgcontext.performAndWait {
            do {
                try bgcontext.save()
            } catch let saveError {
                error = saveError
            }
        }
        if let error = error {throw error}
    }
}
