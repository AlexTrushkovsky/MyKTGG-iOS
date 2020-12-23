//
//  ListViewController.swift
//  UBottomSheet_Example
//
//  Created by ugur on 2.05.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    var sheetCoordinator: UBottomSheetCoordinator?
    let sheetNetworkController = BottomSheetNetworkController()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        tableView.register(UINib(nibName: "MapItemCell", bundle: nil), forCellReuseIdentifier: "MapItemCell")
        sheetNetworkController.addItem(title: "Будильник", subtitle: "на 1 вересня спрацює через 52:25", image: "alarm", date: Date())
        sheetNetworkController.addItem(title: "Заміна", subtitle: "самостійна робота першою парою у вівторок", image: "change", date: Date())
        sheetNetworkController.addItem(title: "День незалежності", subtitle: "нашій вітчизні вже 29", image: "new", date: Date())
        sheetNetworkController.addItem(title: "Увага", subtitle: "всі студенти запрошуються в актову залу о 15:10", image: "alarm", date: Date())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sheetCoordinator?.startTracking(item: self)
    }
    
    func hideNotificationPalceholder(bool: Bool) {
//            noNotificationImage.isHidden = bool
//            noNotificationLabel.isHidden = bool
    }
    
    func configureCell(cell: MapItemCell, indexPath: IndexPath) {
        print("config")
        let model = sheetNetworkController.sheetModel
        guard let items = model.items else { return }
        let item = items[indexPath.row]
        if let image = item.image {
            cell.leftImageView.image = UIImage(named: image)
        }
//        if let date = item.date {
//            cell.leftImageView = UIImage(named: image)
//        }
        if let title = item.title {
            cell.nameLabel.text = title
        }
        if let subtitle = item.subtitle {
            cell.descriptionLabel.text = subtitle
        }
    }
}

extension ListViewController: Draggable{
    func draggableView() -> UIScrollView? {
        return tableView
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let model = sheetNetworkController.sheetModel
        if model.items?.count == nil {
            hideNotificationPalceholder(bool: false)
        } else {
            hideNotificationPalceholder(bool: true)
        }
        return model.items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapItemCell", for: indexPath) as! MapItemCell
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
    
}

