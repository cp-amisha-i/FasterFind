//
//  UnsplashAPI.swift
//  UnsplashGame
//
//  Created by Amisha I on 25/08/21.
//

import Foundation

struct ImageType: Hashable, Decodable {
    let regular: String
}

struct RandomImageResponse: Decodable {
    let urls: ImageType
}

enum UnsplashAPI {
    static let accessToken = "JkcGhmw9roTJKcZitbUlSZhYvEUbt6g_-MLW53A1vGg"
    
    static func getRandomImage(completion: @escaping (RandomImageResponse?) -> Void) {
        let url = URL(string: "https://api.unsplash.com/photos/random/?client_id=\(accessToken)")!
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let session = URLSession(configuration: config)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("Accept-Version", forHTTPHeaderField: "v1")
        
        session.dataTask(with: urlRequest) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let data = data, error == nil,
                let decodedResponse = try? JSONDecoder().decode(RandomImageResponse.self, from: data)
            else {
                completion(nil)
                return
            }
            
            completion(decodedResponse)
        }.resume()
    }
}
