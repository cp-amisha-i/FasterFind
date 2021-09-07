//
//  UnsplashAPI.swift
//  UnsplashGame
//
//  Created by Amisha I on 25/08/21.
//

import Combine
import Foundation

struct ImageType: Hashable, Decodable {
    let regular: String
}

struct RandomImageResponse: Decodable {
    let urls: ImageType
}

enum UnsplashAPI {
    static let accessToken = "JkcGhmw9roTJKcZitbUlSZhYvEUbt6g_-MLW53A1vGg"
    
    static func generateRandomImage() -> AnyPublisher<RandomImageResponse, GameError> {
        let url = URL(string: "https://api.unsplash.com/photos/random/?client_id=\(accessToken)")!
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession(configuration: config)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("Accept-Version", forHTTPHeaderField: "v1")
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { response in
                guard let httpURLResponse = response.response as? HTTPURLResponse, httpURLResponse.statusCode == 200
                else {
                    throw GameError.statusCode
                }
                return response.data
            }
            .decode(type: RandomImageResponse.self, decoder: JSONDecoder())
            .mapError { GameError.map($0) }
            .eraseToAnyPublisher()
    }
}
