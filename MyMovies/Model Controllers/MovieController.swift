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
    
    
    //MARK: Networking for movies - Encoding
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
    
    //MARK: Networking
    //PUT
    var baseURL2 = URL(string: "https://task-coredata.firebaseio.com/")!
    
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
    
    //save persistentStore
    func saveToPersistentStore() {
        do {
            let moc = CoreDataStack.shared.mainContext
            try moc.save()
        } catch {
            NSLog("Error saving managed object context:\(error)")
        }
    }
    
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
    
}
