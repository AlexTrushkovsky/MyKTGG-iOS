//
//  ViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import AVFoundation
import UBottomSheet
import StoreKit

class MainViewController: UIViewController {
    var sheetCoordinator: UBottomSheetCoordinator!
    var backView: PassThroughView?
    let weather = weatherController()
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var weatherTempLabel: UILabel!
    @IBOutlet weak var weatherDescription: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var search: UIButton!
    
    @IBAction func turnOnTorch(_ sender: UIButton) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            let torchOn = !device.isTorchActive
            try device.setTorchModeOn(level: 1.0)
            device.torchMode = torchOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Error toggling Flashlight: \(error)")
        }
    }
    private func showTorchNotSupported() {
        let alertController = UIAlertController(title: "Flashlight is not supported", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Understand", style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeather), name:NSNotification.Name(rawValue: "updateWeather"), object: nil)
        makeElementsTransparent(bool: true)
        getAutoPromotionInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        EnterCount()
        weather.fetchData()
    }
    
    @objc func updateWeather() {
        print("set up weather")
        let temp = weather.weatherModel.main?.temp
        let icon = weather.weatherModel.weather![0].icon
        let description = weather.weatherModel.weather![0].description
        makeElementsTransparent(bool: false)
        weatherIcon.image = UIImage(named: icon ?? "01d")
        weatherTempLabel.text = "\(Int(temp ?? 0))°"
        weatherDescription.text = description
    }
    
    func makeElementsTransparent(bool: Bool) {
        if bool {
            weatherIcon.alpha = 0
            weatherTempLabel.alpha = 0
            weatherDescription.alpha = 0
            mainImage.alpha = 0
            search.alpha = 0
        } else {
            UIImageView.animate(withDuration: 0.2) {
                self.weatherIcon.alpha = 1
            }
            UIView.animate(withDuration: 0.2) {
                self.weatherTempLabel.alpha = 1
            }
            UIView.animate(withDuration: 0.2) {
                self.weatherDescription.alpha = 1
            }
            UIView.animate(withDuration: 0.2) {
                self.mainImage.alpha = 1
            }
            UIView.animate(withDuration: 0.2) {
                self.search.alpha = 1
            }
        }
    }
    
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        guard sheetCoordinator == nil else {return}
        sheetCoordinator = UBottomSheetCoordinator(parent: self,
                                                   delegate: self)
        
        let vc = AppleMapsSheetViewController()
        vc.sheetCoordinator = sheetCoordinator
        sheetCoordinator.addSheet(vc, to: self, didContainerCreate: { container in
            let f = self.view.frame
            let rect = CGRect(x: f.minX, y: f.minY, width: f.width, height: f.height)
            container.roundCorners(corners: [.topLeft, .topRight], radius: 10, rect: rect)
        })
        sheetCoordinator.setCornerRadius(10)
    }
    
    private func addBackDimmingBackView(below container: UIView){
        backView = PassThroughView()
        self.view.insertSubview(backView!, belowSubview: container)
        backView!.translatesAutoresizingMaskIntoConstraints = false
        backView!.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        backView!.bottomAnchor.constraint(equalTo: container.topAnchor, constant: 10).isActive = true
        backView!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        backView!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    
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
}

extension MainViewController: UBottomSheetCoordinatorDelegate{
    
    func bottomSheet(_ container: UIView?, didPresent state: SheetTranslationState) {
        //        self.addBackDimmingBackView(below: container!)
        self.sheetCoordinator.addDropShadowIfNotExist()
        self.handleState(state)
    }
    
    func bottomSheet(_ container: UIView?, didChange state: SheetTranslationState) {
        handleState(state)
    }
    
    func bottomSheet(_ container: UIView?, finishTranslateWith extraAnimation: @escaping ((CGFloat) -> Void) -> Void) {
        extraAnimation({ percent in
            self.backView?.backgroundColor = UIColor.black.withAlphaComponent(percent/100 * 0.8)
        })
    }
    
    func handleState(_ state: SheetTranslationState){
        switch state {
        case .progressing(_, let percent):
            self.backView?.backgroundColor = UIColor.black.withAlphaComponent(percent/100 * 0.8)
        case .finished(_, let percent):
            self.backView?.backgroundColor = UIColor.black.withAlphaComponent(percent/100 * 0.8)
        default:
            break
        }
    }
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
