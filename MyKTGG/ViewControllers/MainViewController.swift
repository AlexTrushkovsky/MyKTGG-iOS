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

    
    @IBAction func logOutAction(_ sender: UIBarButtonItem) {
        do{
            try Auth.auth().signOut()
        }catch{
            print(error)
        }
    }
    
    @IBOutlet weak var WelcomeLabel: UILabel!
    @IBOutlet weak var GroupLabel: UILabel!
    @IBAction func restart(_ sender: Any){
    }
    
    let pullUpController = SOPullUpControl()
    
    var bottomPadding: CGFloat {
        let window = UIApplication.shared.keyWindow
        return window?.safeAreaInsets.top ?? 0.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let user = Auth.auth().currentUser
        _ = user?.displayName ?? "Невідомий"
        pullUpController.dataSource = self
        pullUpController.setupCard(from: view)
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

