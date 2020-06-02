//
//  ChangeController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 16.05.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation
import Alamofire

class ChangeController {
    var change = Change()
    var day = Date()
    public func fetchData(tableView: UITableView){
        guard let group = UserDefaults.standard.object(forKey: "group") as? String else { return }
        let formattedGroup = group.replacingOccurrences(of: "-", with: " ", options: .literal, range: nil)
        let jsonUrlString = "http://217.76.201.219:5000/change/\(formattedGroup.encodeUrl)"
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
                decoder.keyDecodingStrategy = .useDefaultKeys
                do {
                    let change = try decoder.decode(Change.self, from: response.data!)
                    self.change = change
                    DispatchQueue.main.async {
                        print("Data saved")
                        //print(self.change)
                        self.getDayOfChange()
                        tableView.reloadData()
                    }
                }catch{
                    print("Failed to convert Data!")
                }
                
            case let .failure(error):
                print("Failed to get JSON: ",error)
            }
        }
    }

    func getDayOfChange() {
        guard let dayString = change.date else { return }
        let dayStringWithoutWords = dayString.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.").inverted)
        //print(dayStringWithoutWords)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        guard let date = dateFormatter.date(from:dayStringWithoutWords) else { return }
        print("Available Changes for: ",date)
        day = date
    }
    
}
extension String{
    var encodeUrl : String
    {
        return self.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    var decodeUrl : String
    {
        return self.removingPercentEncoding!
    }
}
