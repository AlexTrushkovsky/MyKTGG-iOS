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
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        sharedDefault!.addObserver(self, forKeyPath: "pushes", options: [.new], context: nil)
        addItemsFromDefaults()
    }
    
    func deleteOutdatedAlarms() {
        for index in 0..<tableView.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? MainItemCell {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
                if let dateOfCell = df.date(from: cell.identifier) {
                    if dateOfCell < Date() {
                        sheetContentController.sheetModel.items!.remove(at: indexPath.row)
                        if var arrayOfPushes = sharedDefault!.object(forKey: "pushes") as? [[String]] {
                            for (index, array) in arrayOfPushes.enumerated() {
                                if array.count > 3 {
                                    if array[4] != cell.identifier {
                                        arrayOfPushes.remove(at: index)
                                    }
                                }
                            }
                            sharedDefault!.set(arrayOfPushes, forKey: "pushes")
                        }
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        deleteOutdatedAlarms()
    }
        
    func addItemsFromDefaults() {
        if let arrayOfPushes = sharedDefault!.object(forKey: "pushes") as? [[String]]{
            for push in arrayOfPushes {
                let title = push[0]
                let body = push[1]
                let image = push[2]
                if push.count > 3 && push[2] == "alarm" {
                    let identifier = push[3]
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
                    if let dateOfCell = df.date(from: identifier) {
                        if dateOfCell > Date() {
                            sheetContentController.addItem(title: title, subtitle: body, image: image, identifier: identifier)
                        }
                    }
                }else{
                    sheetContentController.addItem(title: title, subtitle: body, image: image)
                }
                print("added \(body) item")
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
        addItemsFromDefaults()
        tableView.reloadSections([0], with: .automatic)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sheetCoordinator?.startTracking(item: self)
    }
    
    // this method handles row deletion
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            if let cell = tableView.cellForRow(at: indexPath) as? MainItemCell {
                if cell.nameLabel.text == "Будильник" {
                    let identifier = cell.identifier
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                }
            }
            sheetContentController.sheetModel.items!.remove(at: indexPath.row)
            var arrayOfPushes = sharedDefault!.object(forKey: "pushes") as? [[String]]
            arrayOfPushes!.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            sharedDefault!.set(arrayOfPushes, forKey: "pushes")
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Видалити") { (action, indexPath) in
            self.tableView.dataSource?.tableView!(self.tableView, commit: .delete, forRowAt: indexPath)
            return
        }
        
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
        if let identifier = item.identifier {
            cell.identifier = identifier
        }
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let model = sheetContentController.sheetModel
        self.itemsCount = model.items?.count ?? 0
        return self.itemsCount
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MainItemCell else { return }
        guard let tabBar = tabBarController else { return }
        if cell.nameLabel.text == "Будильник" || cell.nameLabel.text == "Заміна" {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
            if let dateOfCell = df.date(from: cell.identifier) {
                UserDefaults.standard.setValue(dateOfCell, forKey: "selectDate")
            }
            tabBar.selectedIndex = 2
        } else {
            tabBar.selectedIndex = 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UINib(nibName: "MainItemCell", bundle: nil), forCellReuseIdentifier: "MainItemCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainItemCell", for: indexPath) as! MainItemCell
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
}
