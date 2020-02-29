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
    var name = ""
    var email = ""
    var password = ""
    
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
        if (signup){
            guard !nameTextField.text!.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup name check")
                return
            }
            guard nameTextField.text!.count<30 else {
                showAlert(title: "Помилка", message: "Ім'я користувача повинно містити не більше 30 символів")
                return
            }
            guard !emailTextField.text!.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup name check")
                return
            }
            guard !passwordTextField.text!.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup pass check")
                return
            }
            name=nameTextField.text!
            email=emailTextField.text!
            password=passwordTextField.text!
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                if error == nil{
                    if let result = result{
                        print(result.user.uid)
                        let ref = Database.database().reference().child("users")
                        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        changeRequest?.displayName = self.name
                        changeRequest?.commitChanges { (error) in }
                        ref.child(result.user.uid).updateChildValues(["name":self.name,"email":self.email])
                        self.dismiss(animated: true, completion: nil)
                    }
                }else{
                    print(error!._code)
                    self.handleError(error!)
                }
            }
        }else{
            guard !emailTextField.text!.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                return
            }
            guard !passwordTextField.text!.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                return
            }
            
            email=emailTextField.text!
            password=passwordTextField.text!
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                if error == nil{
                    
                    let user = Auth.auth().currentUser
                    self.name = user?.displayName ?? "Невідомий"
                    self.email = user?.email ?? "no email"
                    self.dismiss(animated: true, completion: nil)
                }else{
                    print(error!._code)
                    self.handleError(error!)
                }
            }
        }
    }
    @IBAction func logSingSwitch(_ sender: UIButton) {
        signup = !signup
    }
}
//  Email SignIn
extension AuthViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (signup){
            if textField == nameTextField {
                textField.resignFirstResponder()
                emailTextField.becomeFirstResponder()
             } else if textField == emailTextField {
                textField.resignFirstResponder()
                passwordTextField.becomeFirstResponder()
             } else if textField == passwordTextField {
                textField.resignFirstResponder()
             }
        }else{
            if textField == emailTextField {
                textField.resignFirstResponder()
                passwordTextField.becomeFirstResponder()
            } else if textField == passwordTextField {
                textField.resignFirstResponder()
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
extension AuthErrorCode {
    var errorMessage: String {
        switch self {
        case .emailAlreadyInUse:
            return "Електронна пошта вже зареєстрована"
        case .userNotFound:
            return "Аккаунту не знайдено. \nПеревірте правильність вводу і спробуйте ще раз!"
        case .userDisabled:
            return "Ваш обліковий запис було заблоковано. \nЗверніться до техпідтримки в \nTelegram: @esen1n25"
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "Будь-ласка, введіть правильну електронну адресу!"
        case .networkError:
            return "Немає зв'язку з сервером. \nСпробуйте будь-ласка пізніше."
        case .weakPassword:
            return "Ваш пароль закороткий. \nВкажіть пароль, що містить більше 6 символів."
        case .wrongPassword:
            return "Пароль невірний. \nСпробуйте ще раз, або натисніть 'Забули пароль', щоб відновити доступ."
        default:
            return "Сталася невідома помилка"
        }
    }
}
extension UIViewController{
    func handleError(_ error: Error) {
        if let errorCode = AuthErrorCode(rawValue: error._code) {
            print(errorCode.errorMessage)
            let alert = UIAlertController(title: "Помилка", message: errorCode.errorMessage, preferredStyle: .alert)

            let okAction = UIAlertAction(title: "ОК", style: .default, handler: nil)

            alert.addAction(okAction)

            self.present(alert, animated: true, completion: nil)

        }
    }

}
