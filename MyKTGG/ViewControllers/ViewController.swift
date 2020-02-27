//
//  ViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase
class ViewController: UIViewController {
    
    @IBAction func logOutAction(_ sender: UIBarButtonItem) {
        do{
            try Auth.auth().signOut()
        }catch{
            print(error)
        }
    }
    @IBOutlet weak var WelcomeLabel: UILabel!
    @IBAction func restart(_ sender: Any) {
        let user = Auth.auth().currentUser
        let username = user?.displayName ?? "Невідомий"
        WelcomeLabel.text = "Welcome, \(username)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let user = Auth.auth().currentUser
        _ = user?.displayName ?? "Невідомий"
    }
    
    
}

