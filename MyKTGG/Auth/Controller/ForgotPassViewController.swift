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
    @IBOutlet weak var restoreLabel: UIView!
    @IBOutlet weak var emailFieldView: UIView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func showAlertOk(alert: UIAlertAction!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillLayoutSubviews() {
        setLabel(view: restoreLabel, text: "Відновлення паролю")
    }
    
    override func viewDidLoad() {
        hideKeyboardWhenTappedAround()
        button.applyGradient(colors: [CustomButton.UIColorFromRGB(0x4BB179).cgColor,CustomButton.UIColorFromRGB(0x1291AB).cgColor])
        emailTextField.delegate = self
        emailTextField.becomeFirstResponder()
        emailFieldView.layer.cornerRadius = 15
        emailTextField.attributedPlaceholder = NSAttributedString(string: "email",
                                                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor (red: 0.65, green: 0.74, blue: 0.82, alpha: 0.5)])
    }
    
    @IBAction func restoreButton(_ sender: UIButton) {
        _ = textFieldShouldReturn(emailTextField)
    }
    
    func setLabel(view: UIView, text: String) {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0.07, green: 0.57, blue: 0.67, alpha: 1.00).cgColor, UIColor(red: 0.29, green: 0.69, blue: 0.47, alpha: 1.00).cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = view.bounds
        view.layer.addSublayer(gradient)
        let label = UILabel(frame: view.bounds)
        label.text = text
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont(name: "SourceSansPro-Bold", size: 30)
        label.textAlignment = .center
        label.layer.shadowOffset = .zero
        label.layer.shadowRadius = 3
        label.layer.shadowOpacity = 0.3
        label.layer.masksToBounds = false
        label.layer.shouldRasterize = true
        label.layer.shadowColor = UIColor(red: 0.02, green: 0.58, blue: 0.26, alpha: 1).cgColor
        view.addSubview(label)
        view.mask = label
    }
}
extension ForgotPassViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var email = ""
        if !emailTextField.text!.isEmpty{
            if (emailTextField.text!.contains("@")){
                email=emailTextField.text!
            }else{
                showAlert(title: "Помилка", message: "Ви ввели не дійсний email")
            }
            if (!email.isEmpty){
                Auth.auth().sendPasswordReset(withEmail: email){ (error) in
                    if error == nil{
                        let alert = UIAlertController(title: "Готово", message: "Перевірте поштову скриньку", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: self.showAlertOk(alert: )))
                        self.present(alert, animated: true, completion: nil)
                    }else{
                        self.showAlert(title: "Помилка", message: "Користувача з даним email не існує")
                    }
                }
            }
        }else{
            showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
        }
        return true
    }
}
