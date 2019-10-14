//
//  MyMoviesTableViewCell.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 10/12/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

class MyMoviesTableViewCell: UITableViewCell {
    @IBOutlet weak var movieTitleLabel: UILabel!
    @IBOutlet weak var watchedButton: UIButton!
    
    var object: Movie? {
        didSet {
            self.updateViews()
        }
    }
    var movieController: MovieController!
    
    @IBAction func watchedButtonTapped(_ sender: Any) {
        guard let movie = self.object else {return}
        self.movieController.toggleSeenButton(for: movie)
    }
    
    private func updateViews() {
        guard let movie = self.object else {return}
        self.movieTitleLabel?.text = movie.title
        if movie.hasWatched {
            self.watchedButton.setTitle("watched", for: .normal)
        } else {
            self.watchedButton.setTitle("unwatched", for: .normal)
        }
    }
}
