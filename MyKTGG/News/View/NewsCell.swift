//
//  NewsCell.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 12.04.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit

class NewsCell: UITableViewCell {
    @IBOutlet weak var NewsImage: UIImageView!
    @IBOutlet weak var rubric: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var heading: UILabel!
    @IBOutlet weak var newsText: UILabel!
    @IBOutlet weak var cellBackground: UIView!
    @IBOutlet weak var dateBackground: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackground.layer.cornerRadius = 15
        dateBackground.layer.cornerRadius = dateBackground.bounds.height/2
        cellBackground.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.00)
        cellBackground.layer.shadowColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1.00).cgColor
        cellBackground.layer.shadowOpacity = 1
        cellBackground.layer.shadowOffset = .init(width: 0, height: 0)
        cellBackground.layer.shadowRadius = 4
        NewsImage.layer.cornerRadius = 15
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(
            x: self.NewsImage.bounds.minX,
            y: 150,
            width: 1000,
            height:  self.NewsImage.bounds.height/2)
        
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor]
        self.NewsImage.layer.insertSublayer(gradientLayer, at: 0)
    }
}
