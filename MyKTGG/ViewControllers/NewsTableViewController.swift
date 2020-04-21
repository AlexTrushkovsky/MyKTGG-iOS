//
//  NewsTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 12.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

class NewsTableViewController: UITableViewController {
    
    public var news = Root()
    private var new = Items()
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }
    
    public func fetchData(){
        let jsonUrlString = "https://ktgg.kiev.ua/uk/news.html?format=json"
        guard let url = URL(string: jsonUrlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                self.news = try decoder.decode(Root.self, from: data)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch let error {
                print("Error serialization json", error)
            }
            
        }.resume()
    }
    
    private func configureCell(cell: NewsCell, for indexPath: IndexPath) {
        
        new = news.items![indexPath.section]
        cell.heading.text = new.title?.withoutHtml
        
        if let created = new.created{
            let date = created.toDate()
            cell.date.text = date?.toString(dateFormat: "dd'.'MM'.'YYYY")
        }
        
        if let rubric = new.category?.name {
            cell.rubric.text = rubric.withoutHtml
        }
        
        if let introtext = new.introtext {
            cell.newsText.text = introtext.withoutHtml
        }
        
        DispatchQueue.global().async {
            var url = ""
            if self.new.imageMedium != "" {
                url = "https://ktgg.kiev.ua\(self.new.imageMedium!)"
            } else {
                print("Zalupa")
            }
            guard let imageUrl = URL(string: url) else { return }
            print(imageUrl)
            guard let imageData = try? Data(contentsOf: imageUrl) else { return }
            
            DispatchQueue.main.async {
                cell.NewsImage!.image = UIImage(data: imageData)
                cell.NewsImage!.layer.cornerRadius = 8
           }
       }
        
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
       return news.items?.count ?? 0
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell") as! NewsCell
        
        configureCell(cell: cell, for: indexPath)
        
        return cell
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is NewsWebView
        {
            let vc = segue.destination as? NewsWebView
            vc?.url = new.link
            vc?.navigationItem.title = new.title
            print("newsVC link: \(new.link)")
        }
    }
}
extension String {
    public var withoutHtml: String {
        guard let data = self.data(using: .utf8) else {
            return self
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }

        return attributedString.string
    }
    public func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss")-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "Europe/Kiev")
        dateFormatter.locale = Locale(identifier: "ua-UA")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date

    }
}
extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

}
