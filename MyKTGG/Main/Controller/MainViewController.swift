//
//  ViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase
import SOPullUpView

class MainViewController: UIViewController {
    
    //let pullUpController = SOPullUpControl()
    
    //    var bottomPadding: CGFloat {
    //        let window = UIApplication.shared.keyWindow
    //        return window?.safeAreaInsets.top ?? 0.0
    //    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //pullUpController.dataSource = self
        //pullUpController.setupCard(from: view)]
        //        self.tabBarController?.tabBar.layer.cornerRadius = 20
        //        self.tabBarController?.tabBar.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
        //        self.tabBarController?.tabBar.layer.masksToBounds = true
        //
        //        let tabBar = UITabBar.appearance()
        //        self.tabBarController?.tabBar.barTintColor = UIColor.green
        if #available(iOS 13.0, *) {
            let appearance = self.tabBarController?.tabBar.standardAppearance
            appearance!.shadowImage = nil
            appearance!.shadowColor = nil
            self.tabBarController?.tabBar.standardAppearance = appearance!;
        } else {
            self.tabBarController?.tabBar.backgroundImage = UIImage()
            self.tabBarController?.tabBar.shadowImage = UIImage()
            
        }
        self.tabBarController?.tabBar.unselectedItemTintColor = UIColor(red: 0.62, green: 0.62, blue: 0.69, alpha: 1.00)
        self.tabBarController?.tabBar.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.00)
    }
}

extension MainViewController: SOPullUpViewDataSource {
    
    
    func pullUpViewCollapsedViewHeight() -> CGFloat {
        return 480
    }
    
    func pullUpViewController() -> UIViewController {
        guard let vc = UIStoryboard(name: "PickedPull", bundle: nil).instantiateInitialViewController() as? PickedPullUpViewController else {return UIViewController()}
        //vc.pullUpControl = self.pullUpController
        return vc
    }
    
    func pullUpViewExpandedViewHeight() -> CGFloat {
        return 500
    }
}

