import UIKit
import Firebase
import FBSDKLoginKit
class AuthViewController: UIViewController {
    var signup:Bool = true{
        willSet{
            if newValue{
                AuthLabel.image = UIImage(named: "createAccountTitle")
                RegisterButton.setImage(UIImage(named: "registerButton"), for: .normal)
                nameTextFieldView.isHidden=false
            }else{
                AuthLabel.image = UIImage(named: "logInTitle")
                nameTextFieldView.isHidden=true
                RegisterButton.setImage(UIImage(named: "loginButton"), for: .normal)
            }
        }
    }
    
    @IBOutlet weak var AuthLabel: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameTextFieldView: UIView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailTextFieldView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordTextFieldView: UIView!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var signInWithAppleButton: UIButton!
    @IBOutlet weak var signInWithFacebookButton: UIButton!
    @IBOutlet weak var signInWithGoogleButton: UIButton!
    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var LoginSubButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
    }
    func showNoAppleAlert(){
        let alert = UIAlertController(title: "Помилка", message: "Вхід з Apple тимчасово недоступний", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func forgonPasswordAction(_ sender: UIButton) {
    }
    @IBAction func signInWithAppleAction(_ sender: UIButton) {
        
        self.showNoAppleAlert()
    }
    @IBAction func signInWithFaceBookAction(_ sender: UIButton) {
        let login = LoginManager()
        login.logIn(permissions: ["email","public_profile"], from: self) {(result, error) in
            if result!.isCancelled{
                print("isCanceled")
            }else{
                if error == nil{
                    GraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: AccessToken.current?.tokenString, version: nil, httpMethod: HTTPMethod(rawValue: "GET")).start(completionHandler: {
                        (nil, result, error) in
                        if error == nil{
                            print(result as Any)
                            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                            Auth.auth().signIn(with: credential, completion: {(result, error) in
                                if error == nil{
                                    print(result?.user.uid as Any)
                                    self.dismiss(animated: true, completion: nil)
                                }else{
                                    print(error as Any)
                                }
                            })
                        }
                    })
                }
            }
        }
    }
    @IBAction func signInWithGoogle(_ sender: UIButton) {
    }
    @IBAction func regOrLogButton(_ sender: UIButton) {
    }
    @IBAction func logSingSwitch(_ sender: UIButton) {
        signup = !signup
    }
    func showAlert(){
        let alert = UIAlertController(title: "Помилка", message: "Всі поля обов'язкові до заповнення", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func showAlertNotEmail(){
        let alert = UIAlertController(title: "Помилка", message: "Ви ввели не дійсний email", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
    extension AuthViewController:UITextFieldDelegate{
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let name = nameTextField.text!
            let email = emailTextField.text!
            let password = passwordTextField.text!
            
            if (signup){
                if(!name.isEmpty && !email.isEmpty && !password.isEmpty){
                    Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                        if error == nil{
                            if let result = result{
                                print(result.user.uid)
                                let ref = Database.database().reference().child("users")
                                ref.child(result.user.uid).updateChildValues(["name":name,"email":email])
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }else if (!email.contains("@")){
                        showAlertNotEmail()
                    }else{
                        showAlert()
                }
            }else{
                if (!email.isEmpty && !password.isEmpty){
                    Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                        if error == nil{
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }else if (!email.contains("@")){
                    showAlertNotEmail()
                }else{
                    showAlert()
                }
            }
            return true
        }
    }
