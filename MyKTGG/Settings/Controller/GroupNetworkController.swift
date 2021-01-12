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
        var request = URLRequest(url: URL(string: "http://217.76.201.218/cgi-bin/timetable_export.cgi?req_type=obj_list&req_mode=\(mode)&req_format=json&coding_mode=WINDOWS-1251&bs=ok")!)
        
        let ip = getIPAddress()
        if  ip.contains("192.168.5") {
            request = URLRequest(url: URL(string: "http://192.168.5.230/cgi-bin/timetable_export.cgi?req_type=obj_list&req_mode=\(mode)&req_format=json&coding_mode=WINDOWS-1251&bs=ok")!)
        }
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
    
    func getIPAddress() -> String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    // wifi = ["en0"]
                    // wired = ["en2", "en3", "en4"]
                    // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]

                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
    
    func formatJson(str: String, isStudent: Bool) -> [String] {
        var result = str.replacingOccurrences(of: "department", with: "")
        result = result.replacingOccurrences(of: "]", with: "")
        result = result.replacingOccurrences(of: "[", with: "")
        result = result.replacingOccurrences(of: "\"", with: "")
        result = result.replacingOccurrences(of: "}", with: "")
        result = result.replacingOccurrences(of: "{:", with: "")
        var arr = result.components(separatedBy: ",")
        if isStudent {
            arr.removeAll { $0.count >= 10 }
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
