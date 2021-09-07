//
//  GameViewController.swift
//  UnsplashGame
//
//  Created by Amisha I on 25/08/21.
//

import UIKit
import Combine

class GameViewController: UIViewController {
    
    @IBOutlet var imageView: [UIImageView]!
    @IBOutlet var imageButton: [UIButton]!
    @IBOutlet var imageLoader: [UIActivityIndicatorView]!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var gameScore = 0
    var gameLevel = 0
    var gameImages: [UIImage] = []
    var gameTimer: AnyCancellable?
    var cancellable: Set<AnyCancellable> = []
    
    var gameState: GameState = .stop {
        didSet {
            switch gameState {
            case .play:
                playGame()
            case .stop:
                pauseGame()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        precondition(!UnsplashAPI.accessToken.isEmpty, "Please provide a valid Unsplash access token!")
        scoreLabel.text = String(gameScore)
    }
    
    @IBAction func playOrPauseAction(_ sender: UIButton) {
        gameState = gameState == .play ? .stop : .play
    }
    
    @IBAction func onImageClick(_ sender: UIButton) {
        let selectedImages = gameImages.filter { $0 == gameImages[sender.tag] }
        if selectedImages.count > 0 {
            playGame()
        } else {
            gameState = .stop
        }
    }
    
    func playGame() {
        gameTimer?.cancel()
        playPauseButton.setTitle("Pause", for: .normal)
        gameLevel += 1
        scoreLabel.text = String(gameScore)
        gameScore += 200
        
        resetImages()
        startLoaders()
        
        let firstImage = UnsplashAPI.generateRandomImage()
            .flatMap { randomImageResponse in
                ImageDownloader.downloadImage(url: randomImageResponse.urls.regular)
            }
        
        let secondImage = UnsplashAPI.generateRandomImage()
            .flatMap { randomImageResponse in
                ImageDownloader.downloadImage(url: randomImageResponse.urls.regular)
            }
        
        firstImage.zip(secondImage)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [unowned self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    print("Error: \(error)")
                    self.gameState = .stop
                }
            }, receiveValue: { [unowned self] first, second in
                self.gameImages = [first, second, second, second].shuffled()
                
                self.scoreLabel.text = "\(self.gameScore)"
                
                self.gameTimer = Timer.publish(every: 0.1, on: RunLoop.main, in: .common)
                    .autoconnect()
                    .sink { [unowned self] _ in
                        self.scoreLabel.text = "\(self.gameScore)"
                        self.gameScore -= 10
                        
                        if self.gameScore < 0 {
                            self.gameScore = 0
                            self.gameTimer?.cancel()
                        }
                    }
                
                self.stopLoaders()
                self.setImages()
            })
            .store(in: &cancellable)
    }
    
    func pauseGame() {
        cancellable.forEach { $0.cancel() }
        gameTimer?.cancel()
        playPauseButton.setTitle("Play", for: .normal)
        gameScore = 0
        gameLevel = 0
        scoreLabel.text = "\(self.gameScore)"
        stopLoaders()
        resetImages()
    }
    
    func setImages() {
        if gameImages.count == 4 {
            for (index, gameImage) in gameImages.enumerated() {
                imageView[index].image = gameImage
            }
        }
    }
    
    func resetImages() {
        cancellable = []
        gameImages = []
        imageView.forEach { $0.image = nil }
    }
    
    func startLoaders() {
        imageLoader.forEach { $0.startAnimating() }
    }
    
    func stopLoaders() {
        imageLoader.forEach { $0.stopAnimating() }
    }
}
