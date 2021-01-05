//
//  ViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import AVFoundation
import StoreKit

class MainViewController: UIViewController {
    let weather = weatherController()
    
    var sheetCoordinator: UBottomSheetCoordinator!
    var sheetVC = ListViewController()
    var dataSource: UBottomSheetCoordinatorDataSource?
    
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var weatherTempLabel: UILabel!
    @IBOutlet weak var weatherDescription: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var search: UIButton!
    @IBOutlet weak var weatherBackgroundView: UIView!
    @IBOutlet weak var chat: UIButton!
    
    //MARK: - Search Button
    @IBAction func searchButton(_ sender: UIButton) {
        if let url = URL(string: "https://ktgg.kiev.ua/uk/") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func chatButton(_ sender: Any) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "chat") as? ChatVC
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var weatherHeightConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        addWeatherUpdateObserver()
        makeElementsTransparent(bool: true)
        makeWeatherTransparent(bool: true)
        getAutoPromotionInfo()
        EnterCount()
        search.layer.cornerRadius = 15
        chat.layer.cornerRadius = 15
        weatherBackgroundView.layer.cornerRadius = 15
        let height = view.frame.height
        if height == 568 {
            weatherDescription.isHidden = true
            weatherHeightConstraint.constant = 38
            
        }
        print("Available height = \(height)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 1) {
            self.search.imageView?.transform = CGAffineTransform(rotationAngle: .pi)
            self.search.imageView?.transform = CGAffineTransform(rotationAngle: .pi * 2)
        }
        makeElementsTransparent(bool: false)
        weather.fetchData()
    }
    override func viewWillLayoutSubviews() {
        setupBottomSheet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    //MARK: - Setup Tabbar
    func setupBottomSheet() {
        guard sheetCoordinator == nil else {return}
        sheetCoordinator = UBottomSheetCoordinator(parent: self)
        if dataSource != nil{
            sheetCoordinator.dataSource = dataSource!
        }
        let vc = sheetVC
        sheetVC.sheetCoordinator = sheetCoordinator
        sheetCoordinator.addSheet(vc, to: self, didContainerCreate: { container in
            let f = self.view.frame
            let rect = CGRect(x: f.minX, y: f.minY, width: f.width, height: f.height)
            container.roundCorners(corners: [.topLeft, .topRight], radius: 30, rect: rect)
        })
    }
    
    func setupTabBar() {
        if #available(iOS 13.0, *) {
            let appearance = self.tabBarController?.tabBar.standardAppearance
            appearance!.shadowImage = nil
            appearance!.shadowColor = nil
            appearance!.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.00)
            self.tabBarController?.tabBar.standardAppearance = appearance!
        } else {
            self.tabBarController?.tabBar.backgroundImage = UIImage()
            self.tabBarController?.tabBar.shadowImage = UIImage()
        }
        self.tabBarController?.tabBar.unselectedItemTintColor = UIColor(red: 0.62, green: 0.62, blue: 0.69, alpha: 1.00)
    }
    //MARK: - Weather Update
    @objc func updateWeather() {
        print("set up weather")
        let temp = weather.weatherModel.main?.temp
        let icon = weather.weatherModel.weather![0].icon
        let description = weather.weatherModel.weather![0].description
        weatherIcon.image = UIImage(named: icon ?? "01d")
        weatherTempLabel.text = "\(Int(temp ?? 0))"
        weatherDescription.text = description
        makeWeatherTransparent(bool: false)
    }
    func addWeatherUpdateObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeather), name:NSNotification.Name(rawValue: "updateWeather"), object: nil)
    }
    
    //MARK: - Make elements transparent before view appear
    func makeElementsTransparent(bool: Bool) {
        if bool {
            mainImage.alpha = 0
            search.alpha = 0
        } else {
            UIView.animate(withDuration: 0.2) {
                self.mainImage.alpha = 1
                self.search.alpha = 1
            }
        }
    }
    
    func makeWeatherTransparent(bool: Bool) {
        if bool {
            weatherIcon.alpha = 0
            weatherTempLabel.alpha = 0
            weatherDescription.alpha = 0
            weatherBackgroundView.alpha = 0
        } else {
            UIImageView.animate(withDuration: 0.3) {
                self.weatherIcon.alpha = 1
                self.weatherTempLabel.alpha = 1
                self.weatherDescription.alpha = 1
                self.weatherBackgroundView.alpha = 1
            }
        }
    }
    // MARK: - Count of enters in app to display rate pop-up
    func EnterCount() {
        if let count = UserDefaults.standard.object(forKey: "EnterCount") as? Int {
            print("count of enter: ", count)
            if count%10==0 {
                SKStoreReviewController.requestReview()
            }
            UserDefaults.standard.set(count+1, forKey: "EnterCount")
        } else {
            UserDefaults.standard.set(1, forKey: "EnterCount")
        }
    }
    //MARK: - Get promotion info BETA
    func getAutoPromotionInfo() {
        guard let status = Bool(UserDefaults.standard.object(forKey: "AutoPromStatus") as? String ?? "") else { return }
        if status {
            let today = Date()
            let year = Calendar.current.component(.year, from: Date())
            guard let firstOfSepCurrentYear = Calendar.current.date(from: DateComponents(year: year, month: 9, day: 1)) else { return }
            if today == firstOfSepCurrentYear {
                guard let group = UserDefaults.standard.object(forKey: "group") as? String else { return }
                guard let groupNum = Int(group.numbersOnly) else { return }
                guard let groupLetters = Int(group.trimmingCharacters(in: .decimalDigits)) else { return }
                if groupNum/10<=5{
                    let newGroup = groupNum*10+groupLetters
                    print(newGroup)
                    UserDefaults.standard.set(newGroup, forKey: "group")
                }
                print("user got promoted!")
            }
        }
    }
    //MARK: - Setup bottom view
}
extension String {
    
    var numbersOnly: String {
        
        let numbers = self.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression,
            range:nil)
        return numbers
    }
}
