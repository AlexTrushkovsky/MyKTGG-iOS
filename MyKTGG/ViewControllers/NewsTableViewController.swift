//
//  NewsTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 12.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class NewsTableViewController: UITableViewController {
    
    public var news = Root()
    private var new = Items()
    private var imageCache = AutoPurgingImageCache()
    let refControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.refreshControl = refControl
        refControl.addTarget(self, action: #selector(refreshNews(_:)), for: .valueChanged)
        refControl.attributedTitle = NSAttributedString(string: "Потягніть для оновлення")
        fetchData()
    }
    
    @objc private func refreshNews(_ sender: Any) {
        fetchData()
    }
    
    private func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true)
        print("alert showed")
    }
    
    public func fetchData(){
        let limit = 15
        let jsonUrlString = "https://ktgg.kiev.ua/uk/news.html?limit=15&format=json"
        
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
                    self.news = try decoder.decode(Root.self, from: response.data!)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.refControl.endRefreshing()
                    }
                }catch{
                    self.refControl.endRefreshing()
                    print("Failed to convert Data!")
                    self.showAlert(title: "Помилка", message: "Не вдалося отримати дані")
                }
                
            case let .failure(error):
                self.refControl.endRefreshing()
                print("Failed to get JSON: ",error)
                self.showAlert(title: "Помилка", message: "Відсутній зв'язок з сервером, спробуйте пізніше")
            }
        }
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
        
        
        
        guard self.new.imageMedium != "" else {
            print("Image not found")
            cell.NewsImage!.image = #imageLiteral(resourceName: "newPlaceholder копия")
            cell.NewsImage!.layer.cornerRadius = 10
            return
        }
        
        let url = "https://ktgg.kiev.ua\(self.new.imageMedium!)"
        guard let imageUrl = URL(string: url) else { return }
        
        
        
        if let image = imageCache.image(withIdentifier: url)
        {
            cell.NewsImage!.image = image
            cell.NewsImage!.layer.cornerRadius = 10
        } else {
            
            AF.request(imageUrl).responseImage { response in
                if case .success(let image) = response.result {
                    print("image downloaded: \(url)")
                    cell.NewsImage!.image = image
                    cell.NewsImage!.layer.cornerRadius = 10
                    self.imageCache.add(image, withIdentifier: url)
                }
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        new = news.items![indexPath.section]
        let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let WebVC:NewsWebView = storyBoard.instantiateViewController(withIdentifier: "NewsWebView") as! NewsWebView
        WebVC.url = new.link
        WebVC.title = new.title
        show(WebVC, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
            
      print("prefetching row of \(indexPaths)")
    }
        
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
            
      print("cancel prefetch row of \(indexPaths)")
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
extension Date{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
