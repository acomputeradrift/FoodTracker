//
//  FoodTrackerAPIRequest.swift
//  FoodTracker
//
//  Created by Jamie on 2018-09-10.
//  Copyright © 2018 Jamie. All rights reserved.
//

import Foundation

    protocol NetworkerType {
        func requestData(with url: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    }
    
    enum FoodTrackerAPIError: Error {
        case badURL
        case requestError
        case invalidJSON
        case parsingError
    }
    
    class FoodTrackerAPIRequest {
        
        var networker: NetworkerType
        
        init(networker: NetworkerType) {
            self.networker = networker
        }
    }
    
    /// Methods that should be called by other classes
    extension FoodTrackerAPIRequest {
        func signUp(userName: String, password: String, completionHandler: @escaping (User?, Error?) -> Void) {
            
            let dict = [
                "username": userName,
                "password": password
            ]
            
            guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else { return }
            
            guard let url = buildURL(endpoint: "signup", httpMethod: "POST", data: data) else {
                completionHandler(nil, FoodTrackerAPIError.badURL)
                return
            }
            
            self.networker.requestData(with: url) { (data, urlRequest, error) in
                
                var json: [String: Any] = [:]
                var result: User? = nil
                do {
                    json = try self.jsonObject(fromData: data, response: urlRequest, error: error)
                    result = try self.parseUserDetails(fromJSON: json)
                } catch let error {
                    completionHandler(nil, error)
                    return
                }
                
                completionHandler(result, nil)
            }
        }
    }

    /// URL
    extension FoodTrackerAPIRequest {
        func buildURL(endpoint: String, httpMethod:String = "GET", data: Data) -> URLRequest? {
            var componenets = URLComponents()
            componenets.scheme = "https"
            componenets.host = "cloud-tracker.herokuapp.com"
            
            guard var componentsURL = componenets.url else{
                print("could not buld URL request")
                return nil
            }
            componentsURL = componentsURL.appendingPathComponent(endpoint)
            var urlRequest = URLRequest(url: componentsURL)
            urlRequest.httpMethod = httpMethod
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data
            return urlRequest
        }
    }

    
    /// JSON Parsing
    extension FoodTrackerAPIRequest {
        
        func jsonObject(fromData data: Data?, response: URLResponse?, error: Error?) throws -> [String: Any] {
            if let error = error {
                throw error
            }
            guard let data = data else {
                throw FoodTrackerAPIError.requestError
            }
            
            return try jsonObject(fromData: data)
        }
        
        func jsonObject(fromData data: Data) throws -> [String: Any] {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let results = jsonObject as? [String: Any] else {
                throw FoodTrackerAPIError.invalidJSON
            }
            return results
        }
        
   // Parse User Details
        func parseUserDetails(fromJSON json: [String: Any]) throws -> User? {
            guard let id = json["id"] as? Int else {
                throw FoodTrackerAPIError.parsingError
            }
            guard let userName = json["username"] as? String else {
                throw FoodTrackerAPIError.parsingError
            }
            guard let password = json["password"] as? String else {
                throw FoodTrackerAPIError.parsingError
            }
            guard let token = json["token"] as? String else {
                throw FoodTrackerAPIError.parsingError
            }
            let newUser = User(id: id, name: userName, password: password, token: token)
            return newUser
        }
        
        
}


