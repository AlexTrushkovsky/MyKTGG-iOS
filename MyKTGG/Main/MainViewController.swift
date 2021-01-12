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
    var alertStatus = AlertStatus.alert
    
    @IBOutlet weak var whitePlaceholder: UIView!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var weatherTempLabel: UILabel!
    @IBOutlet weak var weatherDescription: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var websiteButton: UIButton!
    @IBOutlet weak var weatherBackgroundView: UIView!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var weatherHeightConstraint: NSLayoutConstraint!

    @IBAction func websiteButton(_ sender: UIButton) {
        if let url = URL(string: "https://ktgg.kiev.ua/uk/") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func chatButton(_ sender: Any) {
        self.setAlert(type: .alert)
        self.alertView.setText(title: "Працюємо", subTitle: "Наразі чат в розробці", body: "очікуйте в настпних версіях")
        self.animateIn()
//        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "chat") as? ChatVC
//        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    private lazy var alertView: CustomAlert = {
            let alertView: CustomAlert = CustomAlert.loadFromNib()
            alertView.delegate = self
            return alertView
        }()
        
        let visualEffectView: UIVisualEffectView = {
            let blurEffect = UIBlurEffect(style: .dark)
            let view = UIVisualEffectView(effect: blurEffect)
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    
    func turnGestures(bool: Bool) {
        guard let gestures = view.gestureRecognizers else { return }
        for gesture in gestures {
            gesture.isEnabled = bool
        }
    }
    
    func setupVisualEffectView() {
        view.addSubview(visualEffectView)
        visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        visualEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        visualEffectView.alpha = 0
    }
    
    func setAlert(type: AlertStatus) {
        self.tabBarController?.setTabBarVisible(visible: false, animated: true)
        alertView = CustomAlert.loadFromNib()
        alertView.delegate = self
        self.alertStatus = type
        view.addSubview(alertView)
        alertView.center = view.center
        alertView.setStyle(type: type)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupVisualEffectView()
        addWeatherUpdateObserver()
        makeElementsTransparent(bool: true)
        makeWeatherTransparent(bool: true)
        EnterCount()
        websiteButton.layer.cornerRadius = 15
        chatButton.layer.cornerRadius = 15
        weatherBackgroundView.layer.cornerRadius = 15
        let height = view.frame.height
        if height <= 568 {
            weatherDescription.isHidden = true
            weatherHeightConstraint.constant = 38
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 1) {
            self.websiteButton.imageView?.transform = CGAffineTransform(rotationAngle: .pi)
            self.websiteButton.imageView?.transform = CGAffineTransform(rotationAngle: .pi * 2)
        }
        makeElementsTransparent(bool: false)
        setupBottomSheet()
        weather.fetchData()
        whitePlaceholder.isHidden = false
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
            print("height: \(f.height)")
            print("width: \(f.width)")
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
            chatButton.alpha = 0
            mainImage.alpha = 0
            websiteButton.alpha = 0
        } else {
            UIView.animate(withDuration: 0.2) {
                self.mainImage.alpha = 1
                self.websiteButton.alpha = 1
                self.chatButton.alpha = 1
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
}
extension MainViewController: CustomAlertDelegate {
    func cancelAction() {
        animateOut()
    }
    
    func okAction() {
        animateOut()
    }
    
    func animateIn() {
            
            turnGestures(bool: false)
            alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            alertView.alpha = 0
            
            UIView.animate(withDuration: 0.3) {
                self.sheetVC.view.alpha = 0
                self.whitePlaceholder.alpha = 0
                self.visualEffectView.alpha = 1
                self.alertView.alpha = 1
                self.alertView.transform = CGAffineTransform.identity
                
            }
        }
        
        func animateOut() {
            
            turnGestures(bool: true)
            UIView.animate(withDuration: 0.3, animations: {
                self.sheetVC.view.alpha = 1
                self.whitePlaceholder.alpha = 1
                self.visualEffectView.alpha = 0
                self.alertView.alpha = 0
                self.alertView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
                self.tabBarController?.setTabBarVisible(visible: true, animated: false)
            }) { (_) in
                self.alertView.removeFromSuperview()
            }
        }
}
