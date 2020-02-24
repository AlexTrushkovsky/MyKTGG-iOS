//
//  ForgotPassViewController.swift
//  authKTGG
//
//  Created by Алексей Трушковский on 18.02.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase
class ForgotPassViewController: UIViewController {
    
    @IBOutlet weak var restoreLabel: UIImageView!
    @IBOutlet weak var emailFieldView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBAction func restoreButton(_ sender: UIButton) {
        let email = emailTextField.text!
        if (!email.isEmpty){
            Auth.auth().sendPasswordReset(withEmail: email){ (error) in
                if error == nil{
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
