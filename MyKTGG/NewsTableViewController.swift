//
//  NewsTableViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 12.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

class NewsTableViewController: UITableViewController {
    
    private var news = Root()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }
    
    func fetchData(){
        let jsonUrlString = "https://ktgg.kiev.ua/uk/news/zahalni.html?format=json"
        guard let url = URL(string: jsonUrlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                self.news = try decoder.decode(Root.self, from: data)
                print(self.news)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch let error {
                print("Error serialization json", error)
            }
            
        }.resume()
    }
    
    private func configureCell(cell: NewsCell, for indexPath: IndexPath) {
        
        let new = news.items![indexPath.section]
        cell.heading.text = new.title
        
        if let created = new.created{
            cell.date.text = created
        }
        
        if let rubric = new.category?.name {
            cell.rubric.text = rubric
        }
        
        if let introtext = new.introtext {
            cell.newsText.text = introtext
        }
        
        DispatchQueue.global().async {
            guard let imageUrl = URL(string: "https://ktgg.kiev.ua\(new.imageMedium!)") else { return }
            print(imageUrl)
            guard let imageData = try? Data(contentsOf: imageUrl) else { return }
            
            DispatchQueue.main.async {
                cell.NewsImage.image = UIImage(data: imageData)
                cell.NewsImage.layer.cornerRadius = 10
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
}
