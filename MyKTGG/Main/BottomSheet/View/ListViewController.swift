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
    let sheetContentController = BottomSheetContentController()
    let sharedDefault = UserDefaults(suiteName: "group.myktgg")
    var itemsCount: Int = 0 {
        didSet {
            if itemsCount == 0 {
                noNewsLabel.isHidden = false
            } else {
                noNewsLabel.isHidden = true
            }
        }
    }
    
    @IBOutlet weak var noNewsLabel: UILabel!
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
//        sheetNetworkController.addItem(title: "Будильник", subtitle: "на 1 вересня спрацює через 52:25", image: "alarm", date: Date())
//        sheetNetworkController.addItem(title: "Заміна", subtitle: "самостійна робота першою парою у вівторок", image: "change", date: Date())
//        sheetNetworkController.addItem(title: "День незалежності", subtitle: "нашій вітчизні вже 29", image: "new", date: Date())
        //        sheetNetworkController.addItem(title: "Увага", subtitle: "всі студенти запрошуються в актову залу о 15:10", image: "alarm", date: Date())
        
        sharedDefault!.addObserver(self, forKeyPath: "pushes", options: [.new], context: nil)
        if let arrayOfPushes = sharedDefault!.object(forKey: "pushes") as? [[String]]{
            for push in arrayOfPushes {
                let title = push[0]
                let body = push[1]
                let image = push[2]
                sheetContentController.addItem(title: title, subtitle: body, image: image)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        updateTableView()
    }
    
   func updateTableView() {
        print("Updating bottomSheet")
        sheetContentController.sheetModel = BottomSheetModel()
        sheetContentController.itemArray = [BottomSheetModelItem]()
    if let arrayOfPushes = sharedDefault!.object(forKey: "pushes") as? [[String]]{
                for push in arrayOfPushes {
                    let title = push[0]
                    let body = push[1]
                    let image = push[2]
                    sheetContentController.addItem(title: title, subtitle: body, image: image)
                }
            }
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sheetCoordinator?.startTracking(item: self)
    }
    
    // this method handles row deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

            // remove the item from the data model
            
            sheetContentController.sheetModel.items!.remove(at: indexPath.row)
            var arrayOfPushes = sharedDefault!.object(forKey: "pushes") as? [[String]]
            arrayOfPushes!.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            sharedDefault!.set(arrayOfPushes, forKey: "pushes")
            

        } else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Видалити") { (action, indexPath) in
            self.tableView.dataSource?.tableView!(self.tableView, commit: .delete, forRowAt: indexPath)
            return
        }
        
//        todayButtonOutlet.setTitleColor(UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00), for: .normal)
        deleteButton.backgroundColor = UIColor(red: 0.77, green: 0.30, blue: 0.30, alpha: 1.00)
        return [deleteButton]
    }
    
    func configureCell(cell: MainItemCell, indexPath: IndexPath) {
        let model = sheetContentController.sheetModel
        guard let items = model.items else { return }
        let item = items[indexPath.row]
        if let image = item.image {
            cell.leftImageView.image = UIImage(named: image)
        }
        if let title = item.title {
            cell.nameLabel.text = title
        }
        if let subtitle = item.subtitle {
            cell.descriptionLabel.text = subtitle
        }
    }
}
