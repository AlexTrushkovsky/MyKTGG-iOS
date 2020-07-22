//
//  weatherController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 17.07.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation
import Alamofire

class weatherController {
    var weatherModel = WeatherModel()
    public func fetchData(){
        let jsonUrlString = "https://api.openweathermap.org/data/2.5/weather?q=kyiv&appid=5744b92815db0d211d94578419b57733&units=metric&lang=ua"
        
        guard let url = URL(string: jsonUrlString) else { return }
        print("Starting to fetch data from \(jsonUrlString)")
        //Alamofire request
        let alamofireSession = AF.request(url, method: .get)
        alamofireSession.validate()
        alamofireSession.responseJSON { response in
            switch response.result {
            case .success:
                print("Validation Successful")
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    self.weatherModel = try decoder.decode(WeatherModel.self, from: response.data!)
                    
                    print(self.weatherModel)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateWeather"), object: nil)
                }catch{
                    //do somethin
                }
                
            case let .failure(error):
                print("Failed to get JSON: ",error)
            }
        }
    }
}
