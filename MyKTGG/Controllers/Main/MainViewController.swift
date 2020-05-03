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
    
    var bottomPadding: CGFloat {
        let window = UIApplication.shared.keyWindow
        return window?.safeAreaInsets.top ?? 0.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //pullUpController.dataSource = self
        //pullUpController.setupCard(from: view)]
//        self.tabBarController?.tabBar.layer.cornerRadius = 20
//        self.tabBarController?.tabBar.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
//        self.tabBarController?.tabBar.layer.masksToBounds = true
    }
}

extension MainViewController: SOPullUpViewDataSource {


    func pullUpViewCollapsedViewHeight() -> CGFloat {
        return bottomPadding + 480
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

