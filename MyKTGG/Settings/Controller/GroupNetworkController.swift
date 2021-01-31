//
//  groupNetworkController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 25.12.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation
import Alamofire

class GroupNetworkController {
    
    public func fetchData(isStudent: Bool) -> [String] {
        var mode = ""
        if isStudent {
            mode = "group"
        } else {
            mode = "teacher"
        }
        var request = URLRequest(url: URL(string: "http://app.ktgg.kiev.ua/cgi-bin/timetable_export.cgi?req_type=obj_list&req_mode=\(mode)&req_format=json&coding_mode=WINDOWS-1251&bs=ok")!)
        var arr = [String]()
        let semaphore = DispatchSemaphore (value: 0)
        request.httpMethod = "GET"
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForResource = 5
        
        URLSession(configuration: config).dataTask(with: request) { (data, response, error) in
            print("trying to get data from decanat")
            guard let data = data else {
                print("Error: \(String(describing: error))")
                semaphore.signal()
                return
            }
            let jsonString = String(data: data, encoding: .windowsCP1251)
            arr = self.formatJson(str: jsonString!, isStudent: isStudent)
            print(arr)
            semaphore.signal()
        }.resume()
        semaphore.wait()
        arr.sort()
        return arr
        
    }
    func formatJson(str: String, isStudent: Bool) -> [String] {
        var result = str.replacingOccurrences(of: "department", with: "")
        result = result.replacingOccurrences(of: "]", with: "")
        result = result.replacingOccurrences(of: "[", with: "")
        result = result.replacingOccurrences(of: "\"", with: "")
        result = result.replacingOccurrences(of: "}", with: "")
        result = result.replacingOccurrences(of: "{", with: "")
        var arr = result.components(separatedBy: ",")
        if isStudent {
            arr.removeAll { $0.contains(":") }
            for i in 0..<arr.count {
                if arr[i].first == " " {
                    arr[i] = String(arr[i].dropFirst())
                }
            }
        } else {
            arr.removeAll { $0.components(separatedBy: ".").count == 1 }
            for i in 0..<arr.count {
                if arr[i].first == " " {
                    arr[i] = String(arr[i].dropFirst())
                }
            }
        }
        return arr
    }
}
