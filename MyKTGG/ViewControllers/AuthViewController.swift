import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
class AuthViewController: UIViewController {
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
    @IBOutlet weak var signInWithGoogleButton: GIDSignInButton!
    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var LoginSubButton: UIButton!
    // Sign/Log in Switch
    var signup:Bool = true{
        willSet{
            if newValue{
                AuthLabel.image = UIImage(named: "createAccountTitle")
                RegisterButton.setImage(UIImage(named: "registerButton"), for: .normal)
                nameTextFieldView.isHidden=false
                LoginSubButton.setTitle("Увійти", for: .normal)
            }else{
                AuthLabel.image = UIImage(named: "logInTitle")
                nameTextFieldView.isHidden=true
                RegisterButton.setImage(UIImage(named: "loginButton"), for: .normal)
                LoginSubButton.setTitle("Зареєструватися", for: .normal)
            }
        }
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func forgonPasswordAction(_ sender: UIButton) {
    }
    //  Apple SignIn
    @IBAction func signInWithAppleAction(_ sender: UIButton) {
        showAlert(title: "Помилка", message: "Авторизація за допомогою Apple на даний час недоступна")
    }
    //  Facebook SignIn
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
    @IBAction func signInWithGoogle(_ sender: GIDSignInButton) {
        GIDSignIn.sharedInstance().delegate=self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
    }
    @IBAction func regOrLogButton(_ sender: UIButton) {
        _ = textFieldShouldReturn(passwordTextField)
    }
    @IBAction func logSingSwitch(_ sender: UIButton) {
        signup = !signup
    }
}
//  Email SignIn
extension AuthViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var name = ""
        var email = ""
        var password = ""
        
        if (signup){
            if !nameTextField.text!.isEmpty{
                name=nameTextField.text!
                textField.resignFirstResponder()
                emailTextField.becomeFirstResponder()
            }else{
               showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup name check")
            }
            if !emailTextField.text!.isEmpty{
                if (emailTextField.text!.contains("@")){
                    email=emailTextField.text!
                    textField.resignFirstResponder()
                    passwordTextField.becomeFirstResponder()
                }else{
                   showAlert(title: "Помилка", message: "Ви ввели недійсний email")
                    print ("Error on signup email check (bad email)")
                }
            }else{
               showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup email check")
            }
            if !passwordTextField.text!.isEmpty{
                password=passwordTextField.text!
            }else{
              showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup pass check")
            }
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                if error == nil{
                    if let result = result{
                        print(result.user.uid)
                        let ref = Database.database().reference().child("users")
                        ref.child(result.user.uid).updateChildValues(["name":name,"email":email])
                        self.dismiss(animated: true, completion: nil)
                    }
                }else{self.showAlert(title: "Помилка", message: "Не вдалося зареєструвати користувача, перевірте дані!")}
            }
        }else{
            if !emailTextField.text!.isEmpty{
                if (emailTextField.text!.contains("@")){
                    email=emailTextField.text!
                    textField.resignFirstResponder()
                    passwordTextField.becomeFirstResponder()
                }else{
                    showAlert(title: "Помилка", message: "Ви ввели недійсний email")
                }
            }else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
            }
            if !passwordTextField.text!.isEmpty{
                password=passwordTextField.text!
            }else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
            }
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                if error == nil{
                    self.dismiss(animated: true, completion: nil)
                }else{self.showAlert(title: "Помилка", message: "Користувача не існує або пароль невірний")}
            }
        }
        return true
    }
}
//  Google SignIn
extension AuthViewController: GIDSignInDelegate{
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Failed to log into Google: ", error)
            return
        }
        print("Succesfuly logged into Google")
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print("Something went wrong with out google user: ", error)
                return
            }
            
            print("Successfully logged into Firebase with Google")
            self.dismiss(animated: true, completion: nil)
        }
    }
}
