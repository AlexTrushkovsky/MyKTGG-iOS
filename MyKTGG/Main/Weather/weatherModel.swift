//
//  weatherModel.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 17.07.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation
struct WeatherModel: Codable {
    var weather: [Weather]?
    var main: Main?
}

struct Main: Codable {
    var temp: Double?
}

struct Weather: Codable {
    var description, icon: String?
    
    enum CodingKeys: String, CodingKey {
        case description
        case icon
    }
}
