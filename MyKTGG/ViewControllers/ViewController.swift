//
//  ViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase
var groupname = ""

class ViewController: UIViewController {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let user = Auth.auth().currentUser
        _ = user?.displayName ?? "Невідомий"
    }
}

