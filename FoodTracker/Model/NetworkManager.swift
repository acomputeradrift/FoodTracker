//
//  NetworkManager.swift
//  FoodTracker
//
//  Created by Jamie on 2018-09-10.
//  Copyright © 2018 Jamie. All rights reserved.
//

import Foundation

class NetworkManager: NetworkerType {
    func requestData(with url: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let dataTask = urlSession.dataTask(with: url, completionHandler: completionHandler)
        dataTask.resume()
    }
}
