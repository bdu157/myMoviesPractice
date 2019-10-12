//
//  MovieSearchTableViewCell.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 10/12/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

class MovieSearchTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    
    var movieRepresentation: MovieRepresentation? {
        didSet {
            self.updateViews()
        }
    }
    var movieController: MovieController!
    
    @IBAction func addMovieButtonTapped(_ sender: Any) {
        guard let movie = self.movieRepresentation else {return}
        self.movieController.addMovie(for: movie)
    }
    
    private func updateViews() {
        guard let movie = self.movieRepresentation else {return}
        self.titleLabel.text = movie.title
    }
}
