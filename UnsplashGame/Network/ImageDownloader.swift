//
//  ImageDownloader.swift
//  UnsplashGame
//
//  Created by Amisha I on 25/08/21.
//

import Foundation
import UIKit
import Combine

enum ImageDownloader {
    static func downloadImage(url: String) -> AnyPublisher<UIImage, GameError> {
        guard let url = URL(string: url) else {
            return Fail(error: GameError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { response -> Data in
                guard
                    let httpURLResponse = response.response as? HTTPURLResponse,
                    httpURLResponse.statusCode == 200
                else {
                    throw GameError.statusCode
                }
                
                return response.data
            }
            .tryMap { data in
                guard let image = UIImage(data: data) else {
                    throw GameError.invalidImage
                }
                return image
            }
            .mapError { GameError.map($0) }
            .eraseToAnyPublisher()
    }
}
