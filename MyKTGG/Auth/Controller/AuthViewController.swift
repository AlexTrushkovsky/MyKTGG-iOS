import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import CryptoKit
import AuthenticationServices

class AuthViewController: UIViewController, ASAuthorizationControllerPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    @IBOutlet weak var AuthLabel: UIView!
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
    @IBOutlet weak var shadowView: UIView!
    
    // Sign/Log in Switch
    var signup:Bool = true{
        willSet{
            if newValue{
                RegisterButton.setTitle("ЗАРЕЄСТРУВАТИ", for: .normal)
                nameTextFieldView.isHidden=false
                LoginSubButton.setTitle("Увійти", for: .normal)
            }else{
                nameTextFieldView.isHidden=true
                RegisterButton.setTitle("УВІЙТИ", for: .normal)
                LoginSubButton.setTitle("Зареєструватися", for: .normal)
            }
        }
    }
    
    var microsoftProvider : OAuthProvider?
    fileprivate var currentNonce: String?
    
    func setLabel(view: UIView, text: String) {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0.07, green: 0.57, blue: 0.67, alpha: 1.00).cgColor, UIColor(red: 0.29, green: 0.69, blue: 0.47, alpha: 1.00).cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.frame = view.bounds
        view.layer.addSublayer(gradient)
        let label = UILabel(frame: view.bounds)
        label.text = text
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
    
    func makeUpdateNotifications() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateAvatar"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLabels"), object: nil)
    }
    
    func subscribeToNewsPushes() {
        Messaging.messaging().subscribe(toTopic: "news") { error in
            print("Subscribed to news")
            UserDefaults.standard.set(true,forKey: "isSubscribedForNews")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        shadowView.layer.cornerRadius = 36
        shadowView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = .zero
        shadowView.layer.shadowRadius = 20
        shadowView.layer.shadowOpacity = 0.2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        nameTextField.delegate = self
        nameTextFieldView.layer.cornerRadius = 15
        emailTextField.delegate = self
        emailTextFieldView.layer.cornerRadius = 15
        passwordTextField.delegate = self
        passwordTextFieldView.layer.cornerRadius = 15
        RegisterButton.applyGradient(colors: [CustomButton.UIColorFromRGB(0x4BB179).cgColor,CustomButton.UIColorFromRGB(0x1291AB).cgColor])
        nameTextField.attributedPlaceholder = NSAttributedString(string: "ім'я та призвіще",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor (red: 0.65, green: 0.74, blue: 0.82, alpha: 0.5)])
        emailTextField.attributedPlaceholder = NSAttributedString(string: "email",
                                                                  attributes: [NSAttributedString.Key.foregroundColor: UIColor (red: 0.65, green: 0.74, blue: 0.82, alpha: 0.5)])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "пароль",
                                                                     attributes: [NSAttributedString.Key.foregroundColor: UIColor (red: 0.65, green: 0.74, blue: 0.82, alpha: 0.5)])
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        hideKeyboardWhenTappedAround()
        self.microsoftProvider = OAuthProvider(providerID: "microsoft.com")
    }
    
    override func viewWillLayoutSubviews() {
        if signup {
            setLabel(view: AuthLabel, text: "Реєстрація")
        } else {
            setLabel(view: AuthLabel, text: "Вхід")
        }
        
    }
    
    func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК",style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func forgotPasswordAction(_ sender: UIButton) {
    }
    //  Apple SignIn
    @IBAction func signInWithAppleAction(_ sender: UIButton) {
        if #available(iOS 13, *) {
            startSignInWithAppleFlow()
        } else {
            showAlert(title: "Потрібне оновлення", message: "Вхід з Apple ID доступний починаючи з iOS 13")
        }
    }

  
    
    
    //  Facebook SignIn
    @IBAction func signInWithFacebookAction(_ sender: UIButton) {
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
                                    let avatarMethods = AvatarMethods()
                                    avatarMethods.getAvatarFromFacebookAcc()
                                    self.makeUpdateNotifications()
                                    self.checkGroupInfoFromFirebase()
                                    self.subscribeToNewsPushes()
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
    
    @IBAction func signInWithTeams(_ sender: UIButton) {
        self.microsoftProvider?.getCredentialWith(_: nil){credential, error in
            if error != nil {
                // Handle error.
            }
            if let credential = credential {
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if error != nil {
                        // Handle error.
                    }
                    
                    guard let authResult = authResult else {
                        print("Couldn't get graph authResult")
                        return
                    }
                    
                    // get credential and token when login successfully
                    let microCredential = authResult.credential as! OAuthCredential
                    let token = microCredential.accessToken!
                    
                    // use token to call Microsoft Graph API
                    self.getUserNameFromTeams(accessToken: token)
                    self.getGroupNameFromTeams(accessToken: token)
                    self.getAvatarFromTeams(accessToken: token)
                    self.checkGroupInfoFromFirebase()
                    self.subscribeToNewsPushes()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func getUserNameFromTeams(accessToken: String) {
        let url = URL(string: "https://graph.microsoft.com/beta/me/displayname/$value")
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            let userName = String(decoding: data!, as: UTF8.self)
            print("Teams userName: \(userName)")
            
            let userID = Auth.auth().currentUser?.uid
            let db = Database.database().reference().child("users")
            db.child(userID!).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let name = value?["name"] as? String ?? ""
                
                if name != "" {
                    UserDefaults.standard.set(name, forKey: "name")
                    print("Teams name:",name)
                } else {
                    db.child(userID!).child("public").updateChildValues(["name":userName]) {
                        (error: Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("Data could not be saved: \(error).")
                        } else {
                            print("Name saved succesfully!")
                            UserDefaults.standard.set(userName, forKey: "name")
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLabels"), object: nil)
                        }
                    }
                }
            }) { (error) in
                print(error.localizedDescription)
            }
            
        }.resume()
    }
    
    func getGroupNameFromTeams(accessToken: String) {
        let url = URL(string: "https://graph.microsoft.com/beta/me/jobtitle/$value")
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            let groupName = String(decoding: data!, as: UTF8.self)
            print("GroupName: \(groupName)")
            
            let userID = Auth.auth().currentUser?.uid
            let db = Database.database().reference()
            db.child("users").child(userID!).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                let group = value?["group"] as? String ?? ""
                let subGroup = value?["subgroup"] as? Int ?? 0
            
                if group != "" {
                    UserDefaults.standard.set(group, forKey: "group")
                    print("getUserDefaults group:",group)
                } else if groupName.count<15 {
                    UserDefaults.standard.set(groupName, forKey: "group")
                    print("setUserDefaults group:",groupName)
                    let ref = Database.database().reference().child("users")
                    let user = Auth.auth().currentUser
                    ref.child(user!.uid).child("public").updateChildValues(["group":groupName]) {
                        (error: Error?, ref:DatabaseReference) in
                        if let error = error {
                            print("Data could not be saved: \(error).")
                        } else {
                            print("groupName saved succesfully!")
                            print(groupName)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateLabels"), object: nil)
                        }
                    }
                } else {
                    print("Failed to get group from teams")
                }
                
                UserDefaults.standard.set(subGroup, forKey: "subGroup")
                print("getUserDefaults subGroup:",subGroup)
            }) { (error) in
                print(error.localizedDescription)
            }
        }.resume()
    }
    
    func getAvatarFromTeams(accessToken: String) {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/photo/$value")
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Couldn't get graph result: \(error)")
                return
            }
            let base64String = data!.base64EncodedString()
            let dataDecoded = Data(base64Encoded: base64String, options: NSData.Base64DecodingOptions(rawValue: 0))!
            if let decodedimage = UIImage(data: dataDecoded) {
                let avatar = AvatarMethods()
                avatar.uploadAvatar(photo: decodedimage) { (result) in
                    switch result {
                    
                    case .success(let url):
                        let ref = Database.database().reference().child("users")
                        let user = Auth.auth().currentUser
                        ref.child(user!.uid).child("public").updateChildValues(["avatarUrl":"\(url)"]) {
                            (error: Error?, ref:DatabaseReference) in
                            if let error = error {
                                print("Data could not be saved: \(error).")
                            } else {
                                print("Photo saved succesfully!")
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateAvatar"), object: nil)
                            }
                        }
                    case .failure(_): break
                    }
                }
            } else {
                print("Failed to get avatar from teams")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateAvatar"), object: nil)
            }
        }.resume()
    }
    
    
    func checkGroupInfoFromFirebase() {
        let userID = Auth.auth().currentUser?.uid
        let db = Database.database().reference()
        db.child("users").child(userID!).child("public").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            
            if let group = value?["group"] as? String {
                UserDefaults.standard.set(group, forKey: "group")
                print("set group from firebase:",group)
            } else {
                print("goto groupChooseVC")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "groupChooseVC"), object: nil)
                return
            }
            
            if let userType = value?["isStudent"] as? Int {
                UserDefaults.standard.set(userType, forKey: "isStudent")
                print("set userType from firebase:",userType)
            } else {
                print("goto groupChooseVC")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "groupChooseVC"), object: nil)
                return
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    
    @IBAction func regOrLogButton(_ sender: UIButton) {
        var name = nameTextField.text!
        var email = emailTextField.text!
        let password = passwordTextField.text!
        if (signup){
            guard !name.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup name check")
                return
            }
            guard name.count<30 else {
                showAlert(title: "Помилка", message: "Ім'я користувача повинно містити не більше 30 символів")
                return
            }
            guard !email.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup name check")
                return
            }
            guard !password.isEmpty else{
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                print ("Error on signup pass check")
                return
            }
            let password = passwordTextField.text!
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                if error == nil{
                    if let result = result{
                        print(result.user.uid)
                        let ref = Database.database().reference().child("users")
                        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        changeRequest?.displayName = name
                        changeRequest?.commitChanges { (error) in }
                        ref.child(result.user.uid).child("public").updateChildValues(["name":name,"email":email])
                        self.checkGroupInfoFromFirebase()
                        self.makeUpdateNotifications()
                        self.subscribeToNewsPushes()
                        self.dismiss(animated: true, completion: nil)
                    }
                }else{
                    print(error!._code)
                    self.handleError(error!)
                }
            }
        }else{
            guard !email.isEmpty else {
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                return
            }
            guard !password.isEmpty else {
                showAlert(title: "Помилка", message: "Всі поля обов'язкові до заповнення")
                return
            }
            
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                if error == nil{
                    let user = Auth.auth().currentUser
                    name = user?.displayName ?? "Невідомий"
                    email = user?.email ?? "no email"
                    self.subscribeToNewsPushes()
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
//  Email SignIn Delegate
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
        Auth.auth().signIn(with: credential) { (firUser, error) in
            if let error = error {
                print("Something went wrong with out google user: ", error)
                return
            }
            let avatarMethods = AvatarMethods()
            avatarMethods.getAvatarFromGoogleAcc()
            print("Successfully logged into Firebase with Google")
            self.getGoogleAccName(user: user)
            self.checkGroupInfoFromFirebase()
            self.makeUpdateNotifications()
            self.subscribeToNewsPushes()
            self.dismiss(animated: true, completion: nil)
            self.dismiss(animated: true, completion: nil)
        }
    }
    func getGoogleAccName(user: GIDGoogleUser) {
        guard let givenName = user.profile.givenName else { return }
        let familyName = user.profile.familyName ?? ""
        let GoogleName = "\(givenName) \(familyName)"
        print(givenName,familyName)
        
        let avatar = AvatarMethods()
        avatar.setAccName(setName: GoogleName)
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
            return "Немає зв'язку з мережею. \n Перевірте з`єднання або спробуйте пізніше."
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
@available(iOS 13.0, *)
extension AuthViewController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            // Save authorised user ID for future reference
            UserDefaults.standard.set(appleIDCredential.user, forKey: "appleAuthorizedUserIdKey")
            
            // Retrieve the secure nonce generated during Apple sign in
            guard let nonce = self.currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }

            // Retrieve Apple identity token
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Failed to fetch identity token")
                return
            }

            // Convert Apple identity token to string
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Failed to decode identity token")
                return
            }

            // Initialize a Firebase credential using secure nonce and Apple identity token
            let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com",
                                                              idToken: idTokenString,
                                                              rawNonce: nonce)
                
            // Sign in with Firebase
            Auth.auth().signIn(with: firebaseCredential) { (authResult, error) in
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                // Mak a request to set user's display name on Firebase
                let changeRequest = authResult?.user.createProfileChangeRequest()
                if appleIDCredential.fullName?.givenName != nil && appleIDCredential.fullName?.familyName != nil{
                    
                    changeRequest?.displayName = "\(appleIDCredential.fullName!.givenName!) \(appleIDCredential.fullName!.familyName!)"
                    changeRequest?.commitChanges(completion: { (error) in

                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            print("Updated display name: \(Auth.auth().currentUser!.displayName!)")
                            let avatar = AvatarMethods()
                            avatar.setAccName(setName: Auth.auth().currentUser!.displayName!)
                        }
                    })
                }
                self.checkGroupInfoFromFirebase()
                self.makeUpdateNotifications()
                self.subscribeToNewsPushes()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    // Handle error.
    print("Sign in with Apple errored: \(error)")
  }

    func startSignInWithAppleFlow() {
      let nonce = randomNonceString()
      currentNonce = nonce
      let appleIDProvider = ASAuthorizationAppleIDProvider()
      let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
      request.nonce = sha256(nonce)

      let authorizationController = ASAuthorizationController(authorizationRequests: [request])
      authorizationController.delegate = self
      authorizationController.presentationContextProvider = self
      authorizationController.performRequests()
    }

    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
}
