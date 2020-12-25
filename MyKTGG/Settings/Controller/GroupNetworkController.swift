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
    public func fetchData() -> [String] {
        let semaphore = DispatchSemaphore (value: 0)
        var arr = [String]()
        let parameters = "{\n    \"to\":\"eRVs75zrFUw-kl6gzqszEK:APA91bH4WbX_KzcMdRBXvCk9W8iAizSO60fxfGHW0It_t2HDpd1J4pJth3_GQ-apHVNhUW0mwDsfNzti12Da6vj1kWWEeKYgILLmHRh0caxu-6B4m7XXN16-J8v7iQXkrv2WN9DKL3x2\",\n    \"notification\": {\n        \"body\":\"Test\",\n        \"title\":\"Test\"\n    }\n}"
        let postData = parameters.data(using: .windowsCP1251)
        
        var request = URLRequest(url: URL(string: "http://217.76.201.218/cgi-bin/timetable_export.cgi?req_type=obj_list&req_mode=group&req_format=json")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=AAAAgPiWVp0:APA91bGLjDDlC-4RnJ_6OwoEacDvLFo1Y1bcEJTfl0H4u16pBIMGZE047vLatzzzBhXf-WNemJC-ePH7nwrQ6x_3-Hku8-H7bEYZ4zkoOHgdNhfevze60zzhvOSClfiJ1MYushqzZgr8", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            let jsonString = String(data: data, encoding: .windowsCP1251)!
            arr = formatJson(str: jsonString)
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        return arr
    }
}

func formatJson(str: String) -> [String] {
    var result = str.replacingOccurrences(of: "department", with: "")
    result = result.replacingOccurrences(of: "]", with: "")
    result = result.replacingOccurrences(of: "[", with: "")
    result = result.replacingOccurrences(of: "\"", with: "")
    result = result.replacingOccurrences(of: "}", with: "")
    result = result.replacingOccurrences(of: "{:", with: "")
    var arr = result.components(separatedBy: ",")
    arr.removeAll { $0.count >= 10 }
    for i in 0..<arr.count {
        if arr[i].first == " " {
            arr[i] = String(arr[i].dropFirst())
        }
    }
    return arr
}
