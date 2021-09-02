//
//  GameViewController.swift
//  UnsplashGame
//
//  Created by Amisha I on 25/08/21.
//

import UIKit

class GameViewController: UIViewController {
    
    @IBOutlet var imageView: [UIImageView]!
    @IBOutlet var imageButton: [UIButton]!
    @IBOutlet var imageLoader: [UIActivityIndicatorView]!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var gameScore = 0
    var gameLevel = 0
    var gameTimer: Timer?
    var gameImages: [UIImage] = []
    
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
        if selectedImages.count == 1 {
            playGame()
        } else {
            gameState = .stop
        }
    }
    
    func playGame() {
        gameTimer?.invalidate()
        playPauseButton.setTitle("Pause", for: .normal)
        gameLevel += 1
        scoreLabel.text = String(gameScore)
        gameScore += 200
        
        resetImages()
        startLoaders()
        
        UnsplashAPI.getRandomImage { [unowned self] randomImageResponse in
            guard let randomImageResponse = randomImageResponse else {
                DispatchQueue.main.async {
                    self.gameState = .stop
                }
                return
            }
            
            ImageDownloader.download(url: randomImageResponse.urls.regular) { [unowned self] image in
                
                guard let image = image else { return }
                self.gameImages.append(image)
                
                UnsplashAPI.getRandomImage { [unowned self] randomImageResponse in
                    guard let randomImageResponse = randomImageResponse else {
                        DispatchQueue.main.async {
                            self.gameState = .stop
                        }
                        return
                    }
                    
                    ImageDownloader.download(url: randomImageResponse.urls.regular) { [unowned self] image in
                        guard let image = image else { return }
                        
                        self.gameImages.append(contentsOf: [image, image, image])
                        self.gameImages.shuffle()
                        
                        DispatchQueue.main.async {
                            scoreLabel.text = String(gameScore)
                            
                            self.gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [unowned self] timer in
                                DispatchQueue.main.async {
                                    scoreLabel.text = String(gameScore)
                                }
                                self.gameScore -= 10
                                
                                if self.gameScore <= 0 {
                                    self.gameScore = 0
                                    timer.invalidate()
                                }
                            }
                            self.stopLoaders()
                            self.setImages()
                        }
                    }
                }
            }
        }
    }
    
    func pauseGame() {
        gameTimer?.invalidate()
        playPauseButton.setTitle("Play", for: .normal)
        gameScore = 0
        gameLevel = 0
        scoreLabel.text = String(gameScore)
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
