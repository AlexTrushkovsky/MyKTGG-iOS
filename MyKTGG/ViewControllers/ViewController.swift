//
//  ViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 17.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var newsCount = 5
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.text = "Hello KTGG"
        return cell!
    }
    
    @IBOutlet var mainTableView: UITableView!
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
        mainTableView.layer.cornerRadius = 40
        
    }
}

